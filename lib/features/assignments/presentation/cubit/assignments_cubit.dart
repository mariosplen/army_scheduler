import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/other_tasks.dart';
import 'package:ls_ypiresies/core/entities/program.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/core/entities/stored_data.dart';
import 'package:ls_ypiresies/core/enums/slot.dart';
import 'package:ls_ypiresies/core/usecases/usecase.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/get_stored_data.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/save_daily.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/sign_date.dart';
import 'package:ls_ypiresies/features/assignments/presentation/cubit/warnings_cubit.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_parser/table_parser.dart';

part 'assignments_state.dart';

class AssignmentsCubit extends Cubit<AssignmentsState> {
  AssignmentsCubit({
    required GetStoredData getStoredData,
    required SaveDaily saveDaily,
    required SignDate signDate,
    WarningsCubit? warningsCubit,
    Date? date,
  })  : _getStoredData = getStoredData,
        _saveDaily = saveDaily,
        _signDate = signDate,
        _warningsCubit = warningsCubit,
        super(
          AssignmentsState(
            daily: Daily.empty(date ?? Date.fromDateTime(DateTime.now())),
          ),
        ) {
    _onInit(state.daily.date);
  }

  final GetStoredData _getStoredData;
  final SaveDaily _saveDaily;
  final SignDate _signDate;
  final WarningsCubit? _warningsCubit;

  late StoredData _storedData;

  final _loadedDailies = <Date, Daily>{};

  Future<void> _onInit(Date date) async {
    emit(state.copyWith(isLoading: true));

    final result = await _getStoredData(NoParams());

    result.fold(
      (exception) {
        _storedData = const StoredData();
        _warningsCubit
            ?.addWarningMsg('Failed to load stored data: $exception');
        emit(state.copyWith(isLoading: false));
      },
      (storedData) {
        _storedData = storedData;

        Date? minDate;
        Date? maxDate;
        if (_storedData.assignments.isNotEmpty) {
          final sortedDates = _storedData.assignments.keys.toList()
            ..sort((a, b) => a.toDateTime().compareTo(b.toDateTime()));
          minDate = sortedDates.first;
          maxDate = sortedDates.last;
        }

        _loadedDailies[date] = _storedData.getDailyFor(date);
        final daily = _loadedDailies[date]!;

        emit(state.copyWith(
          isLoading: false,
          daily: daily,
          minDate: minDate,
          maxDate: maxDate,
        ));

        _warningsCubit?.calculateWarnings(daily, getAllDailies());
      },
    );
  }

  /// Returns all known dailies, with in-memory edits taking precedence over
  /// stored data.
  Map<Date, Daily> getAllDailies() {
    return {..._storedData.assignments, ..._loadedDailies};
  }

  /// Returns the daily for the day before the currently displayed date, or
  /// null if not available.
  Daily? getPreviousDaily() {
    final previousDate = Date.fromDateTime(
      state.daily.date.toDateTime().subtract(const Duration(days: 1)),
    );
    return getAllDailies()[previousDate];
  }

  Future<void> signDay() async {
    emit(state.copyWith(isLoading: true));

    final result = await _signDate(SignDateParams(state.daily.date));

    result.fold(
      (exception) {
        _warningsCubit?.addWarningMsg('Failed to sign date: $exception');
        emit(state.copyWith(isLoading: false));
      },
      (_) {
        final signedDaily = state.daily.copyWith(isSigned: true);
        _loadedDailies[state.daily.date] = signedDaily;
        _storedData.assignments[state.daily.date] = signedDaily;
        emit(state.copyWith(isLoading: false, daily: signedDaily));
      },
    );
  }

  /// Returns all dates that have unsaved in-memory changes, sorted
  /// chronologically.
  List<Date> getUnsavedDates() {
    final unsaved = <Date>[];
    _loadedDailies.forEach((date, daily) {
      if (daily != _storedData.getDailyFor(date)) unsaved.add(date);
    });
    unsaved.sort((a, b) => a.toDateTime().compareTo(b.toDateTime()));
    return unsaved;
  }

  Future<void> saveAll(List<Date> dates) async {
    emit(state.copyWith(isLoading: true));
    for (final date in dates) {
      final daily = _loadedDailies[date];
      if (daily == null) continue;

      final result = await _saveDaily(SaveDailyParams(daily));
      result.fold(
        (exception) => _warningsCubit?.addWarningMsg(
            'Failed to save ${date.toReadableString()}: $exception'),
        (_) => _storedData.assignments[date] = daily,
      );
    }
    emit(state.copyWith(isLoading: false));
  }

  bool hasChanges() {
    final stored = _storedData.assignments[state.daily.date];
    return stored == null || stored != state.daily;
  }

  void onPressedPrevDay() => _updateDate(-1);

  void onPressedNextDay() => _updateDate(1);

  void onNewDatePicked(Date newDate) {
    _updateDate(
        newDate.toDateTime().difference(state.daily.date.toDateTime()).inDays);
  }

  void _updateDate(int dayOffset) {
    final newDate = Date.fromDateTime(
      state.daily.date.toDateTime().add(Duration(days: dayOffset)),
    );

    if (state.minDate != null &&
        newDate.toDateTime().isBefore(state.minDate!.toDateTime())) {
      _warningsCubit?.addWarningMsg(
          'Δεν υπάρχει Excel για πριν ${state.minDate!.toReadableString()}');
      return;
    }
    if (state.maxDate != null &&
        newDate.toDateTime().isAfter(state.maxDate!.toDateTime())) {
      _warningsCubit?.addWarningMsg(
          'Δεν υπάρχει Excel για μετά ${state.maxDate!.toReadableString()}');
      return;
    }

    _loadedDailies[newDate] ??= _storedData.getDailyFor(newDate);
    emit(state.copyWith(daily: _loadedDailies[newDate]));
    _warningsCubit?.calculateWarnings(state.daily, getAllDailies());
  }

  Future<void> saveChanges() async {
    emit(state.copyWith(isLoading: true));

    final result = await _saveDaily(SaveDailyParams(state.daily));
    result.fold(
      (exception) {
        _warningsCubit?.addWarningMsg('Failed to save daily: $exception');
        emit(state.copyWith(isLoading: false));
      },
      (_) {
        _storedData.assignments[state.daily.date] = state.daily;
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  void addSoldier(String name) {
    final newSoldier = Soldier(name: name, role: 'ΕΝΙΣΧΥΣΗ');
    final currentManpower = List<Soldier>.from(state.daily.manpower);

    if (!currentManpower.contains(newSoldier)) {
      currentManpower.add(newSoldier);
      final updatedDaily = state.daily.copyWith(manpower: currentManpower);
      _loadedDailies[state.daily.date] = updatedDaily;
      emit(state.copyWith(daily: updatedDaily));
    }
  }

  int getTotalServicesForMonth(Soldier soldier) =>
      _storedData.getTotalServicesForMonth(
          soldier: soldier, date: state.daily.date);

  int getTotalReservesForMonth(Soldier soldier) =>
      _storedData.getTotalReservesForMonth(
          soldier: soldier, date: state.daily.date);

  int getTotalLeavesForMonth(Soldier soldier) =>
      _storedData.getTotalLeavesForMonth(
          soldier: soldier, date: state.daily.date);

  int getTotalExitsForMonth(Soldier soldier) =>
      _storedData.getTotalExitsForMonth(
          soldier: soldier, date: state.daily.date);

  int getDaysSinceLastExit(Soldier soldier) =>
      _storedData.getDaysSinceLastExit(
          soldier: soldier, date: state.daily.date);

  void _emitDailyUpdate(Daily updatedDaily) {
    _loadedDailies[state.daily.date] = updatedDaily;
    emit(state.copyWith(daily: updatedDaily));
    _warningsCubit?.calculateWarnings(updatedDaily, getAllDailies());
  }

  void _updateOtherTasks(OtherTasks Function(OtherTasks) updater) {
    final updated = updater(state.daily.otherTasks);
    if (updated != state.daily.otherTasks) {
      _emitDailyUpdate(state.daily.copyWith(otherTasks: updated));
    }
  }

  void _updateProgram(Program Function(Program) updater) {
    final updated = updater(state.daily.program);
    if (updated != state.daily.program) {
      _emitDailyUpdate(state.daily.copyWith(program: updated));
    }
  }

  List<Soldier> _updateList(
    List<Soldier> source,
    Soldier? soldier,
    bool isAdding, {
    int? maxItems,
  }) {
    final list = List<Soldier>.from(source);
    if (isAdding) {
      if (soldier != null && !list.contains(soldier)) {
        if (maxItems != null && list.length >= maxItems) list.removeAt(0);
        list.add(soldier);
      }
    } else {
      list.remove(soldier);
    }
    return list;
  }

  void onAssign({
    Soldier? soldier,
    required Slot slot,
    bool isAdding = true,
  }) {
    if (state.daily.isSigned) {
      _warningsCubit?.addWarningMsg(
          'Cannot modify assignments for a signed day (${state.daily.date}).');
      return;
    }

    switch (slot) {
      case Slot.flagRising:
        _updateOtherTasks((t) => t.copyWith(
            flagRising: soldier == null
                ? []
                : _updateList(t.flagRising, soldier, isAdding)));
        break;
      case Slot.flagLowering:
        _updateOtherTasks((t) => t.copyWith(
            flagLowering: soldier == null
                ? []
                : _updateList(t.flagLowering, soldier, isAdding)));
        break;
      case Slot.post1:
        _updateProgram((p) => p.copyWith(post1: isAdding ? soldier : null));
        break;
      case Slot.hiddenPost1:
        _updateProgram(
            (p) => p.copyWith(hiddenPost1: isAdding ? soldier : null));
        break;
      case Slot.post2:
        _updateProgram((p) => p.copyWith(post2: isAdding ? soldier : null));
        break;
      case Slot.hiddenPost2:
        _updateProgram(
            (p) => p.copyWith(hiddenPost2: isAdding ? soldier : null));
        break;
      case Slot.post3:
        _updateProgram((p) => p.copyWith(post3: isAdding ? soldier : null));
        break;
      case Slot.hiddenPost3:
        _updateProgram(
            (p) => p.copyWith(hiddenPost3: isAdding ? soldier : null));
        break;
      case Slot.dormGuard1:
        _updateProgram(
            (p) => p.copyWith(dormGuard1: isAdding ? soldier : null));
        break;
      case Slot.dormGuard2:
        _updateProgram(
            (p) => p.copyWith(dormGuard2: isAdding ? soldier : null));
        break;
      case Slot.dormGuard3:
        _updateProgram(
            (p) => p.copyWith(dormGuard3: isAdding ? soldier : null));
        break;
      case Slot.reserveDormGuard1:
        _updateOtherTasks(
            (t) => t.copyWith(reserveDormGuard1: isAdding ? soldier : null));
        break;
      case Slot.reserveDormGuard2:
        _updateOtherTasks(
            (t) => t.copyWith(reserveDormGuard2: isAdding ? soldier : null));
        break;
      case Slot.reserveDormGuard3:
        _updateOtherTasks(
            (t) => t.copyWith(reserveDormGuard3: isAdding ? soldier : null));
        break;
      case Slot.reservePost1:
        _updateOtherTasks(
            (t) => t.copyWith(reservePost1: isAdding ? soldier : null));
        break;
      case Slot.reservePost2:
        _updateOtherTasks(
            (t) => t.copyWith(reservePost2: isAdding ? soldier : null));
        break;
      case Slot.reservePost3:
        _updateOtherTasks(
            (t) => t.copyWith(reservePost3: isAdding ? soldier : null));
        break;
      case Slot.reserveHiddenPost1:
        _updateOtherTasks(
            (t) => t.copyWith(reserveHiddenPost1: isAdding ? soldier : null));
        break;
      case Slot.reserveHiddenPost2:
        _updateOtherTasks(
            (t) => t.copyWith(reserveHiddenPost2: isAdding ? soldier : null));
        break;
      case Slot.reserveHiddenPost3:
        _updateOtherTasks(
            (t) => t.copyWith(reserveHiddenPost3: isAdding ? soldier : null));
        break;
      case Slot.gep:
        _updateProgram((p) => p.copyWith(gep: isAdding ? soldier : null));
        break;
      case Slot.kitchen:
        _updateProgram((p) => p.copyWith(kitchen: isAdding ? soldier : null));
        break;
      case Slot.dutySergeant:
        _updateProgram(
            (p) => p.copyWith(dutySergeant: isAdding ? soldier : null));
        break;
      case Slot.dpvCanteen:
        _updateProgram(
            (p) => p.copyWith(dpvCanteen: isAdding ? soldier : null));
        break;
      case Slot.divisionCanteen:
        _updateProgram((p) => p.copyWith(
            divisionCanteen: soldier == null
                ? []
                : _updateList(p.divisionCanteen, soldier, isAdding)));
        break;
      case Slot.detached:
        _updateProgram((p) => p.copyWith(
            detached: _updateList(p.detached, soldier, isAdding)));
        break;
      case Slot.kpsm:
        _updateOtherTasks(
            (t) => t.copyWith(kpsm: isAdding ? soldier : null));
        break;
      case Slot.cleanBinArea:
        _updateOtherTasks(
            (t) => t.copyWith(cleanBinArea: isAdding ? soldier : null));
        break;
      case Slot.cleanDormGuardArea:
        _updateOtherTasks(
            (t) => t.copyWith(cleanDormGuardArea: isAdding ? soldier : null));
        break;
      case Slot.cleanSupervisorArea:
        _updateOtherTasks((t) => t.copyWith(
            cleanSupervisorArea: soldier == null
                ? []
                : _updateList(t.cleanSupervisorArea, soldier, isAdding,
                    maxItems: 2)));
        break;
      case Slot.cleanDivisionArea:
        _updateOtherTasks((t) => t.copyWith(
            cleanDivisionArea: soldier == null
                ? []
                : _updateList(t.cleanDivisionArea, soldier, isAdding,
                    maxItems: 2)));
        break;
      case Slot.cleanToiletsArea:
        _updateOtherTasks((t) => t.copyWith(
            cleanToiletsArea: soldier == null
                ? []
                : _updateList(t.cleanToiletsArea, soldier, isAdding,
                    maxItems: 2)));
        break;
      case Slot.cleanBarracksArea:
        _updateOtherTasks((t) => t.copyWith(
            cleanBarracksArea: soldier == null
                ? []
                : _updateList(t.cleanBarracksArea, soldier, isAdding,
                    maxItems: 2)));
        break;
      case Slot.passengerForFoodLunch:
        _updateOtherTasks((t) =>
            t.copyWith(passengerForFoodLunch: isAdding ? soldier : null));
        break;
      case Slot.passengerForFoodDinner:
        _updateOtherTasks((t) =>
            t.copyWith(passengerForFoodDinner: isAdding ? soldier : null));
        break;
      case Slot.foodTransferLunch:
        _updateOtherTasks((t) => t.copyWith(
            foodTransferLunch: soldier == null
                ? []
                : _updateList(t.foodTransferLunch, soldier, isAdding,
                    maxItems: 2)));
        break;
      case Slot.foodTransferDinner:
        _updateOtherTasks((t) => t.copyWith(
            foodTransferDinner: soldier == null
                ? []
                : _updateList(t.foodTransferDinner, soldier, isAdding,
                    maxItems: 2)));
        break;
      default:
        _warningsCubit?.addWarningMsg('Unhandled slot: $slot');
    }
  }

  /// Returns soldiers available for assignment the following day.
  List<Soldier> getAvailableSoldiersOfTomorow() {
    final tomorrow = Date.fromDateTime(
        state.daily.date.toDateTime().add(const Duration(days: 1)));
    final tomorrowDaily = getAllDailies()[tomorrow];

    final unavailable = [
      tomorrowDaily?.program.kitchen,
      ...?tomorrowDaily?.program.onLeave,
      tomorrowDaily?.program.dpvCanteen,
      ...?tomorrowDaily?.program.detached,
      ...?tomorrowDaily?.program.exempt,
    ];

    return tomorrowDaily?.manpower
            .where((s) =>
                !unavailable.contains(s) && s.role != 'ΕΝΙΣΧΥΣΗ')
            .toList() ??
        [];
  }

  /// Returns soldiers not currently assigned to any primary service.
  List<Soldier> getAvailableSoldiers() {
    final unavailable = [
      state.daily.program.gep,
      state.daily.program.kitchen,
      ...state.daily.program.onLeave,
      state.daily.program.dpvCanteen,
      ...state.daily.program.detached,
      ...state.daily.program.exempt,
      state.daily.program.dormGuard1,
      state.daily.program.dormGuard2,
      state.daily.program.dormGuard3,
      state.daily.program.post1,
      state.daily.program.hiddenPost1,
      state.daily.program.post2,
      state.daily.program.hiddenPost2,
      state.daily.program.post3,
      state.daily.program.hiddenPost3,
    ];

    return state.daily.manpower
        .where((s) => !unavailable.contains(s) && s.role != 'ΕΝΙΣΧΥΣΗ')
        .toList();
  }

  /// Returns the scheduled flag-lowering time for the current date.
  String getFlagLoweringTime() {
    final date = state.daily.date;
    final day = date.day;
    final month = date.month;
    final year = date.year;

    DateTime lastSunday(int m, int y) {
      final lastDay = DateTime(y, m + 1, 0);
      return lastDay.subtract(Duration(days: lastDay.weekday % 7));
    }

    switch (month) {
      case 1:
        return day <= 15 ? '16:50' : '17:10';
      case 2:
        return day <= 15 ? '17:25' : '17:40';
      case 3:
        if (day <= 15) return '17:55';
        final dt = date.toDateTime();
        return (dt.isAfter(lastSunday(3, year)) ||
                dt.isAtSameMomentAs(lastSunday(3, year)))
            ? '19:10'
            : '18:10';
      case 4:
        return day <= 15 ? '19:25' : '19:40';
      case 5:
        return day <= 15 ? '19:50' : '20:05';
      case 6:
        return day <= 15 ? '20:15' : '20:20';
      case 7:
        return day <= 15 ? '20:20' : '20:10';
      case 8:
        return day <= 15 ? '20:00' : '19:40';
      case 9:
        return day <= 15 ? '19:15' : '18:50';
      case 10:
        if (day <= 15) return '18:30';
        final dt = date.toDateTime();
        return (dt.isAfter(lastSunday(10, year)) ||
                dt.isAtSameMomentAs(lastSunday(10, year)))
            ? '17:00'
            : '18:05';
      case 11:
        return day <= 15 ? '16:50' : '16:40';
      case 12:
        return day <= 15 ? '16:35' : '16:40';
      default:
        return '';
    }
  }

  Future<void> printDaily() async {
    emit(state.copyWith(isLoading: true));
    try {
      final ByteData data = await rootBundle.load('assets/template.xlsx');
      final buffer =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final newExcel = TableParser.decodeBytes(buffer, update: true);

      _fillServicesSheet(newExcel);
      _fillOaaSheet(newExcel);

      try {
        _updateDynamologioSheet(newExcel);
      } catch (e) {
        debugPrint('Error updating ΚΑΤΑΣΤΑΣΗ sheet: $e');
        _warningsCubit?.addWarningMsg(
            'Could not update ΚΑΤΑΣΤΑΣΗ sheet. Ensure it exists in the template.');
      }

      final fileBytes = newExcel.encode();

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: 'new_file',
          ext: 'xlsx',
          bytes: Uint8List.fromList(fileBytes),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final packageInfo = await PackageInfo.fromPlatform();
        final date = state.daily.date;
        final yy = (date.year % 100).toString().padLeft(2, '0');
        final mm = date.month.toString().padLeft(2, '0');
        final targetDir = Directory(
            '${directory.path}/${packageInfo.appName}/${yy}_$mm');

        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        final filePath =
            '${targetDir.path}/${date.toFileNameString()}.xlsx';
        File(filePath).writeAsBytesSync(fileBytes);
        await OpenFile.open(filePath);
        await saveChanges();
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      debugPrint('Error in printDaily: $e');
      _warningsCubit?.addWarningMsg('Failed to print daily: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  // ---------------------------------------------------------------------------
  // Excel export helpers
  // ---------------------------------------------------------------------------

  void _fillServicesSheet(TableParser newExcel) {
    const sheet = 'ΥΠΗΡΕΣΙΕΣ';
    final d = state.daily;
    final o = d.otherTasks;
    final p = d.program;

    void cell(int col, int row, dynamic value) =>
        newExcel.updateCell(sheet, col, row, value);

    // Date header
    cell(0, 2, d.date.toGreekString());

    // Posts (with reserve suffix when applicable)
    String postText(Soldier? main, Soldier? reserve, String hours) =>
        reserve == null
            ? (main?.name ?? '')
            : '${main?.name ?? ''} (${reserve.name} ΤΟ $hours)';

    final kolHourPost3 =
        p.post3?.role == 'ΤΑΧ' ? '6-8 ΕΠΟΜΕΝΗΣ' : '12-14';
    final kolHourHiddenPost3 =
        p.hiddenPost3?.role == 'ΤΑΧ' ? '6-8 ΕΠΟΜΕΝΗΣ' : '12-14';

    cell(4, 5, postText(p.post1, o.reservePost1, '8-10'));
    cell(5, 5, postText(p.hiddenPost1, o.reserveHiddenPost1, '8-10'));
    cell(4, 9, postText(p.post2, o.reservePost2, '10-12'));
    cell(5, 9, postText(p.hiddenPost2, o.reserveHiddenPost2, '10-12'));
    cell(4, 13, postText(p.post3, o.reservePost3, kolHourPost3));
    cell(5, 13, postText(p.hiddenPost3, o.reserveHiddenPost3, kolHourHiddenPost3));

    // Dorm guards (with reserve suffix)
    cell(4, 18, o.reserveDormGuard1 == null
        ? (p.dormGuard1?.name ?? '')
        : '${p.dormGuard1?.name ?? ''} (${o.reserveDormGuard1!.name} ΤΟ 9-12)');
    cell(4, 21, o.reserveDormGuard2 == null
        ? (p.dormGuard2?.name ?? '')
        : '${p.dormGuard2?.name ?? ''} (${o.reserveDormGuard2!.name} ΤΟ 12-15)');
    cell(4, 24, o.reserveDormGuard3 == null
        ? (p.dormGuard3?.name ?? '')
        : '${p.dormGuard3?.name ?? ''} (${o.reserveDormGuard3!.name} ΤΟ 6-9 ΤΗΣ ΕΠΟΜΕΝΗΣ)');

    // Flag ceremonies
    cell(2, 28,
        o.flagRising.isEmpty ? '' : o.flagRising.map((s) => s.name).join(' - '));
    cell(4, 32, '(${getFlagLoweringTime()})');
    cell(2, 33,
        o.flagLowering.isEmpty ? '' : o.flagLowering.map((s) => s.name).join(' - '));

    // Cleaning duties
    cell(2, 39, _joinNames(o.cleanSupervisorArea));
    cell(4, 39, _joinNames(o.cleanDivisionArea));
    cell(2, 43, _joinNames(o.cleanToiletsArea));
    cell(4, 43, o.cleanBinArea?.name ?? '');
    cell(2, 47, _joinNames(o.cleanBarracksArea));
    cell(4, 47, o.cleanDormGuardArea?.name ?? '');

    // Food logistics
    cell(2, 51, _joinNames(o.foodTransferLunch));
    cell(4, 51, o.passengerForFoodDinner?.name ?? '');
    cell(2, 55, _joinNames(o.foodTransferDinner));
    cell(4, 55, o.passengerForFoodLunch?.name ?? '');

    // Miscellaneous services
    cell(1, 12, p.gep?.name ?? o.execGep?.name ?? '');
    cell(1, 14, p.kitchen?.name ?? '');
    cell(1, 9, p.dutySergeant?.name ?? '');

    // Roles from manpower list
    cell(1, 10,
        d.manpower.firstWhereOrNull((s) => s.role == 'ΔΠΒ')?.name ?? '');
    cell(1, 11,
        d.manpower.firstWhereOrNull((s) => s.role == 'ΔΜΧ')?.name ?? '');
    cell(1, 15,
        d.manpower.firstWhereOrNull((s) => s.role == 'ΤΑΧ')?.name ?? '');

    // Executive officers
    cell(1, 4, o.execDutySupervisor?.name ?? '');
    cell(1, 5, o.execDutyOfficer?.name ?? '');
    cell(1, 6, o.execDutyOfficerMP?.name ?? '');
    cell(1, 7, o.execGateGuard?.name ?? '');
    cell(1, 13, o.execCook?.name ?? '');
    cell(1, 20, o.execDutySupervisor?.name ?? '');
    cell(1, 21, o.execDutyOfficerMP?.name ?? '');
    cell(1, 22, o.execDutyOfficer?.name ?? '');

    // CCTV officers
    cell(1, 27, o.execCCTV1?.name ?? '');
    cell(1, 51, o.execCCTV1?.name ?? '');
    cell(1, 30, o.execCCTV2?.name ?? '');
    cell(1, 53, o.execCCTV2?.name ?? '');
    cell(1, 8, o.execCCTV2?.name ?? '');

    // ΗΣΑ3: append ΔΠΒ soldier's name if officer has role 'ΒΝΣ'
    String hsa3Name = o.execCCTV3?.name ?? '';
    if (o.execCCTV3?.role == 'ΒΝΣ') {
      final dpvSoldier =
          d.manpower.firstWhereOrNull((s) => s.role == 'ΔΠΒ');
      if (dpvSoldier != null) hsa3Name = '$hsa3Name (${dpvSoldier.name})';
    }
    cell(1, 33, hsa3Name);

    // Free / exit soldiers
    final homeSleepersNames =
        _storedData.homeSleepers.map((s) => s.name).toSet();

    final freeInside = <Soldier>[];
    final freeOutside = <Soldier>[];

    for (final soldier in d.canLeaveBase) {
      if (homeSleepersNames.contains(soldier.name)) {
        freeOutside.add(soldier);
      } else {
        freeInside.add(soldier);
      }
    }
    freeInside.removeWhere((s) => s.role == 'ΕΝΙΣΧΥΣΗ');

    // ΕΣΤ soldiers who sleep at home always get a ΔΝ exit card
    final alwaysDn = d.manpower.firstWhereOrNull(
        (s) => s.role == 'ΕΣΤ' && homeSleepersNames.contains(s.name));
    if (alwaysDn != null &&
        !freeOutside.contains(alwaysDn) &&
        !p.onLeave.contains(alwaysDn) &&
        alwaysDn.role != 'ΕΝΙΣΧΥΣΗ') {
      freeOutside.add(alwaysDn);
    }

    // Write free-inside soldiers (column C) and fill exit cards sheet
    for (int i = 0; i < freeInside.length; i++) {
      cell(2, 58 + i, freeInside[i].name);
    }

    // Write free-outside (ΔΝ) soldiers (column D)
    for (int i = 0; i < freeOutside.length; i++) {
      cell(3, 58 + i, freeOutside[i].name);
    }

    // On-leave and exempt columns
    for (int i = 0; i < p.onLeave.length; i++) {
      cell(4, 58 + i, p.onLeave[i].name);
    }
    for (int i = 0; i < p.exempt.length; i++) {
      cell(5, 58 + i, p.exempt[i].name);
    }

    // Fill ΕΞΟΔΟΧΑΡΤΑ sheet (exit passes)
    _fillExitPassesSheet(newExcel, freeInside);

    // Fill ΔΝ sheet (home-sleeper passes)
    _fillDnSheet(newExcel, freeOutside);
  }

  void _fillExitPassesSheet(TableParser excel, List<Soldier> soldiers) {
    const sheet = 'ΕΞΟΔΟΧΑΡΤΑ';
    const maxSlots = 32;

    final d = state.daily;
    final fromTime = d.isSunday || d.isHoliday
        ? '10:00'
        : d.isSaturday
            ? '12:00'
            : '15:00';
    const untilTime = '22:30';
    final dateString = d.date.toReadableString();

    for (int i = 0; i < soldiers.length && i < maxSlots; i++) {
      final baseRow = 6 + (i ~/ 2) * 14;
      final timeRow = baseRow + 1;
      final dateRow = baseRow + 3;
      final nameCol = i % 2 == 0 ? 2 : 9;

      excel.updateCell(sheet, nameCol, baseRow, soldiers[i].name);

      if (i % 2 == 0) {
        excel.updateCell(sheet, 3, timeRow, fromTime);
        excel.updateCell(sheet, 5, timeRow, untilTime);
        excel.updateCell(sheet, 4, dateRow, dateString);
      } else {
        excel.updateCell(sheet, 10, timeRow, fromTime);
        excel.updateCell(sheet, 12, timeRow, untilTime);
        excel.updateCell(sheet, 11, dateRow, dateString);
      }
    }
  }

  void _fillDnSheet(TableParser excel, List<Soldier> soldiers) {
    const sheet = 'ΔΝ';
    const maxSlots = 16;
    final dateString = state.daily.date.toReadableString();

    for (int i = 0; i < soldiers.length && i < maxSlots; i++) {
      final baseRow = 6 + (i ~/ 2) * 14;
      final dateRow = baseRow + 3;
      final nameCol = i % 2 == 0 ? 2 : 9;

      excel.updateCell(sheet, nameCol, baseRow, soldiers[i].name);

      if (i % 2 == 0) {
        excel.updateCell(sheet, 4, dateRow, dateString);
      } else {
        excel.updateCell(sheet, 11, dateRow, dateString);
      }
    }
  }

  void _fillOaaSheet(TableParser newExcel) {
    const sheet = 'ΟΑΑ-ΤΑΕ';
    final o = state.daily.otherTasks;
    final p = state.daily.program;

    void cell(int col, int row, String? value) =>
        newExcel.updateCell(sheet, col, row, value ?? '');

    String res(Soldier? reserve, Soldier? main) =>
        reserve?.name ?? main?.name ?? '';

    // Rows 2–10: with reserve fallback
    cell(1, 1, res(o.reservePost2, p.post2));
    cell(1, 2, res(o.reservePost3, p.post3));
    cell(1, 3, res(o.reserveHiddenPost2, p.hiddenPost2));
    cell(1, 4, res(o.reservePost1, p.post1));
    cell(1, 5, res(o.reservePost3, p.post3));
    cell(1, 6, res(o.reserveHiddenPost3, p.hiddenPost3));
    cell(1, 7, res(o.reservePost1, p.post1));
    cell(1, 8, res(o.reservePost2, p.post2));
    cell(1, 9, res(o.reserveHiddenPost1, p.hiddenPost1));
    cell(2, 3, res(o.reserveHiddenPost2, p.hiddenPost2));
    cell(2, 6, res(o.reserveHiddenPost3, p.hiddenPost3));
    cell(2, 9, res(o.reserveHiddenPost1, p.hiddenPost1));

    // Rows 11–34: without reserve
    cell(1, 10, p.post2?.name);
    cell(1, 11, p.post3?.name);
    cell(1, 12, p.hiddenPost2?.name);
    cell(1, 13, p.post1?.name);
    cell(1, 14, p.post3?.name);
    cell(1, 15, p.hiddenPost3?.name);
    cell(1, 16, p.post1?.name);
    cell(1, 17, p.post2?.name);
    cell(1, 18, p.hiddenPost1?.name);
    cell(1, 19, p.post3?.name);
    cell(1, 20, p.post2?.name);
    cell(1, 21, p.hiddenPost2?.name);
    cell(1, 22, p.post1?.name);
    cell(1, 23, p.post3?.name);
    cell(1, 24, p.hiddenPost3?.name);
    cell(1, 25, p.post1?.name);
    cell(1, 26, p.post2?.name);
    cell(1, 27, p.hiddenPost1?.name);
    cell(1, 28, p.post2?.name);
    cell(1, 29, p.post3?.name);
    cell(1, 30, p.hiddenPost2?.name);
    cell(1, 31, p.post1?.name);
    cell(1, 32, p.post3?.name);
    cell(1, 33, p.hiddenPost3?.name);
    cell(2, 12, p.hiddenPost2?.name);
    cell(2, 15, p.hiddenPost3?.name);
    cell(2, 18, p.hiddenPost1?.name);
    cell(2, 21, p.post2?.name);
    cell(2, 24, p.post3?.name);
    cell(2, 27, p.post1?.name);
    cell(2, 30, p.post2?.name);
    cell(2, 33, p.post3?.name);
  }

  void _updateDynamologioSheet(TableParser newExcel) {
    const sheetName = 'ΚΑΤΑΣΤΑΣΗ';
    final d = state.daily;

    final soldiers = List<Soldier>.from(d.manpower)
      ..removeWhere((s) => s.role == 'ΕΝΙΣΧΥΣΗ')
      ..sort((a, b) {
        final unitA = (a.unit ?? '').toUpperCase();
        final unitB = (b.unit ?? '').toUpperCase();
        final isLsA = unitA.contains('ΛΣ') || unitA == 'Λ.Σ.';
        final isLsB = unitB.contains('ΛΣ') || unitB == 'Λ.Σ.';
        if (isLsA && !isLsB) return -1;
        if (!isLsA && isLsB) return 1;
        final unitComp = unitA.compareTo(unitB);
        if (unitComp != 0) return unitComp;
        final dateA = _parseDate(a.dateofArival);
        final dateB = _parseDate(b.dateofArival);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

    newExcel.updateCell(sheetName, 3, 1, d.date.toReadableString());

    // Determine ΔΝ (home-sleeper exit) soldiers
    final homeSleepersNames =
        _storedData.homeSleepers.map((s) => s.name).toSet();
    final freeOutside = <Soldier>[];
    for (final s in d.canLeaveBase) {
      if (homeSleepersNames.contains(s.name)) freeOutside.add(s);
    }
    final alwaysDn = d.manpower.firstWhereOrNull(
        (s) => s.role == 'ΕΣΤ' && homeSleepersNames.contains(s.name));
    if (alwaysDn != null && !freeOutside.contains(alwaysDn)) {
      freeOutside.add(alwaysDn);
    }

    // Summary statistics
    int onLeave = 0, detached = 0, dn = 0, exempt = 0, gep = 0;
    for (final s in soldiers) {
      if (d.program.onLeave.contains(s)) {
        onLeave++;
      } else if (d.program.detached.contains(s)) {
        detached++;
      } else if (freeOutside.contains(s)) {
        dn++;
      } else if (d.program.exempt.contains(s)) {
        exempt++;
      } else if (d.program.gep == s) {
        gep++;
      }
    }

    newExcel.updateCell(sheetName, 6, 7, soldiers.length);
    newExcel.updateCell(sheetName, 6, 8, onLeave);
    newExcel.updateCell(sheetName, 6, 9, dn);
    newExcel.updateCell(sheetName, 6, 10, gep);
    newExcel.updateCell(sheetName, 6, 11, exempt);
    newExcel.updateCell(sheetName, 6, 12, detached);

    const soldiersStartRow = 5;
    for (int i = 0; i < soldiers.length; i++) {
      final s = soldiers[i];
      final row = i + soldiersStartRow;
      newExcel.insertRow(sheetName, row);

      newExcel.updateCell(sheetName, 0, row, (i + 1).toString());
      newExcel.updateCell(sheetName, 1, row, s.rank ?? '');
      newExcel.updateCell(sheetName, 2, row, s.name);
      newExcel.updateCell(sheetName, 3, row, s.unit ?? '');
      newExcel.updateCell(sheetName, 4, row, s.phoneNumber ?? '');
      newExcel.updateCell(sheetName, 6, row, s.role ?? '');

      String status = s.note ?? '';

      if (d.program.onLeave.contains(s)) {
        // Calculate the last consecutive leave date
        var checkDate = d.date;
        var lastLeaveDate = checkDate;
        while (true) {
          final nextDate = Date.fromDateTime(
              checkDate.toDateTime().add(const Duration(days: 1)));
          if (!_storedData.assignments.containsKey(nextDate)) break;
          final nextDaily = _storedData.assignments[nextDate]!;
          if (!nextDaily.program.onLeave.contains(s)) break;
          lastLeaveDate = nextDate;
          checkDate = nextDate;
        }
        final dd = lastLeaveDate.day.toString().padLeft(2, '0');
        final mm = lastLeaveDate.month.toString().padLeft(2, '0');
        final yy = (lastLeaveDate.year % 100).toString().padLeft(2, '0');
        status = 'ΑΔΕΙΑ ΕΩΣ ΚΑΙ $dd/$mm/$yy';
      } else if (d.program.detached.contains(s)) {
        status = 'ΔΙΑΘΕΣΗ';
      } else if (freeOutside.contains(s)) {
        status = 'ΔΝ';
      } else if (d.program.exempt.contains(s)) {
        status = 'ΕΥ';
      } else if (d.program.gep == s) {
        status = 'ΓΕΠ';
      }

      newExcel.updateCell(sheetName, 5, row, status);
    }
  }

  String _joinNames(List<Soldier> soldiers) =>
      soldiers.isEmpty ? '' : soldiers.map((s) => s.name).join(' - ');

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
