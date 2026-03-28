import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/other_tasks.dart';
import 'package:ls_ypiresies/core/entities/program.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/core/entities/stored_data.dart';
import 'package:path/path.dart' as p;
import 'package:table_parser/table_parser.dart';

abstract class AssignmentsDataSource {
  Future<StoredData> getStoredData();
  Future<void> saveDaily(Daily daily);
  Future<void> signDate(Date date);
}

const monthToPrefixMap = {
  1: 'ΙΑΝ', 2: 'ΦΕΒ', 3: 'ΜΑΡ', 4: 'ΑΠΡ', 5: 'ΜΑΙ', 6: 'ΙΟΥΝ',
  7: 'ΙΟΥΛ', 8: 'ΑΥΓ', 9: 'ΣΕΠ', 10: 'ΟΚΤ', 11: 'ΝΟΕ', 12: 'ΔΕΚ',
};

// Column indices for the main soldier roster in each month sheet
const namesStartRow = 9;
const namesStartColumn = 1;
const rolesStartColumn = 2;
const iDStartColumn = 5;
const phoneNumberStartColumn = 6;
const unitStartColumn = 7;
const physicalAbilityStartColumn = 8;
const notesStartColumn = 9;
const rankStartColumn = 10;
const essoStartColumn = 11;
const dateOfArrivalStartColumn = 12;
const daysStartRow = 8;
const daysStartCol = 13;

class AssignmentsDataSourceImpl implements AssignmentsDataSource {
  final TableParser excel;
  final String json;
  final String baseDocsPath;

  /// In-memory cache of all OtherTasks JSON data, keyed by ISO date string.
  /// Preserved across saves so that history from earlier dates is not lost.
  late Map<String, dynamic> _masterJsonMap;

  AssignmentsDataSourceImpl({
    required this.excel,
    required this.json,
    required this.baseDocsPath,
  }) {
    try {
      _masterJsonMap = json.isNotEmpty ? jsonDecode(json) : {};
    } catch (_) {
      _masterJsonMap = {};
    }
  }

  /// Returns the folder path for a specific date: `baseDocsPath/YY_MM/DD_MM_YY/`
  String _getDailyFolderPath(Date date) {
    final yy = (date.year % 100).toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return p.join(baseDocsPath, '${yy}_$mm', '${dd}_${mm}_$yy');
  }

  @override
  Future<void> saveDaily(Daily daily) async {
    final date = daily.date;
    final sheetName =
        '${monthToPrefixMap[date.month]}${(date.year % 100)}';

    if (!excel.tables.containsKey(sheetName)) {
      throw Exception('Sheet $sheetName not found in Excel file.');
    }
    final sheet = excel.tables[sheetName]!;

    // Locate the column for this date
    int? dateColIndex;
    for (int col = daysStartCol; col < sheet.maxCols; col++) {
      final cell = sheet.rows[daysStartRow][col];
      final d = _parseDateCell(cell);
      if (d != null && d == date) {
        dateColIndex = col;
        break;
      }
    }
    if (dateColIndex == null) {
      throw Exception(
          'Date ${date.toReadableString()} not found in sheet $sheetName.');
    }

    // Build a name → assignment-code map
    final Map<String, String> assignments = {};
    void add(Soldier? s, String code) {
      if (s != null) assignments[s.name] = code;
    }

    final program = daily.program;
    add(daily.otherTasks.kpsm, 'ΕΞ');
    add(program.post1, 'ΣΚ1');
    add(program.hiddenPost1, 'ΣΚ1');
    add(program.post2, 'ΣΚ2');
    add(program.hiddenPost2, 'ΣΚ2');
    add(program.post3, 'ΣΚ3');
    add(program.hiddenPost3, 'ΣΚ3');
    add(program.dormGuard1, 'ΘΑΛ1');
    add(program.dormGuard2, 'ΘΑΛ2');
    add(program.dormGuard3, 'ΘΑΛ3');
    add(program.kitchen, 'ΕΣΤ');
    add(program.gep, 'ΓΕΠ');
    add(program.dutySergeant, 'ΛΥΛ');
    add(program.dpvCanteen, 'ΔΠΒ');
    for (final s in program.detached) add(s, 'ΔΙΑΘ');
    for (final s in program.onLeave) add(s, 'ΑΔΕΙΑ');
    for (final s in program.exempt) add(s, 'ΕΥ');
    for (final s in program.divisionCanteen) {
      if (!daily.cantLeaveBase.contains(s)) add(s, 'ΚΥΛ');
    }
    for (final s in daily.totalFree) {
      if (program.dpvCanteen == null || s.name != program.dpvCanteen?.name) {
        add(s, 'ΕΞ');
      }
    }

    // Map soldier names to their row indices, locate the ΤΕΛΟΣ sentinel row
    final Map<String, int> nameToRow = {};
    int? telosRowIndex;

    for (int row = namesStartRow; row < sheet.maxRows; row++) {
      final val = sheet.rows[row][namesStartColumn]?.trim();
      if (val == 'ΤΕΛΟΣ') {
        telosRowIndex = row;
        break;
      }
      if (val != null && val.isNotEmpty) nameToRow[val] = row;
    }

    // Write each assignment into the sheet, inserting rows for new soldiers
    for (final entry in assignments.entries) {
      final name = entry.key;
      final code = entry.value;

      int? rowIndex = nameToRow[name];

      if (rowIndex == null && code == 'ΓΕΠ') continue;

      if (rowIndex == null) {
        if (telosRowIndex == null) {
          throw Exception('ΤΕΛΟΣ sentinel row not found in sheet $sheetName.');
        }
        rowIndex = telosRowIndex;
        excel.insertRow(sheetName, rowIndex);
        excel.updateCell(sheetName, namesStartColumn, rowIndex, name);

        final soldier =
            daily.manpower.firstWhereOrNull((s) => s.name == name);
        final roleToWrite =
            (soldier?.role == 'ΕΝΙΣΧΥΣΗ') ? 'ΕΝΙΣΧΥΣΗ' : '-';
        excel.updateCell(sheetName, rolesStartColumn, rowIndex, roleToWrite);

        // Fill future date columns with ΤΕΛΟΣ so parsing terminates correctly
        for (int c = daysStartCol; c < sheet.maxCols; c++) {
          if (sheet.rows[daysStartRow][c] is num) {
            excel.updateCell(sheetName, c, rowIndex, 'ΤΕΛΟΣ');
          }
        }

        telosRowIndex++;
        nameToRow[name] = rowIndex;
      }

      excel.updateCell(sheetName, dateColIndex, rowIndex, code);
    }

    // Persist OtherTasks to the in-memory JSON cache
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    _masterJsonMap[dateKey] = daily.otherTasks.toJson();

    // Write excel.xlsx and tasks.json to the monthly folder
    final monthlyPath = p.dirname(_getDailyFolderPath(date));
    await Directory(monthlyPath).create(recursive: true);

    await File(p.join(monthlyPath, 'excel.xlsx'))
        .writeAsBytes(excel.encode());

    await File(p.join(monthlyPath, 'tasks.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(_masterJsonMap),
      encoding: utf8,
    );
  }

  @override
  Future<StoredData> getStoredData() async {
    final otherTasksMap = _parseOtherTasksFromCache();

    final daysGep = _parseSheetToMap('ΓΕΠ');
    final daysCook = _parseSheetToMap('ΜΑΓΕΙΡΑΣ');
    final daysDutySupervisor = _parseSheetToMap('ΕΑΣ');
    final daysDutyOfficer = _parseSheetToMap('ΑΥΔΜ ΛΣ');
    final daysDutyOfficerMP = _parseSheetToMap('ΑΥΔΜ ΛΣΝ');
    final daysCCTV1 = _parseSheetToMap('ΗΣΑ1');
    final daysCCTV2 = _parseSheetToMap('ΗΣΑ2');
    final daysCCTV3 = _parseSheetToMap('ΗΣΑ3');
    final daysGateGuard = _parseSheetToMap('ΑΡΧΙΦΥΛΑΚΑΣ');
    final homeSleepers = _parseSimpleList('ΔΝ');
    final holidays = _parseHolidays('ΑΡΓΙΕΣ');
    final marketClosedDays = _parseHolidays('ΠΡΑΤΗΡΙΟ');

    // Find all month sheets matching the pattern ΜΑΡ26, ΑΠΡ26, etc.
    final prefixPattern =
        monthToPrefixMap.values.map(RegExp.escape).join('|');
    final sheetPattern =
        RegExp('^($prefixPattern)(2[0-9]|3[0-9]|40)\$');
    final relevantSheets =
        excel.tables.keys.where(sheetPattern.hasMatch);

    final Map<Date, Daily> assignments = {};
    for (final sheetName in relevantSheets) {
      final currentSheet = excel.tables[sheetName];
      if (currentSheet == null) continue;

      for (int col = daysStartCol; col < currentSheet.maxCols; col++) {
        final daily = _processDayColumn(
          currentSheet,
          col,
          otherTasksMap,
          daysGep,
          daysCook,
          daysDutySupervisor,
          daysDutyOfficer,
          daysDutyOfficerMP,
          daysCCTV1,
          daysCCTV2,
          daysCCTV3,
          daysGateGuard,
          holidays,
          marketClosedDays,
        );
        if (daily != null) assignments[daily.date] = daily;
      }
    }

    return StoredData(
      assignments: assignments,
      daysGep: daysGep,
      daysCook: daysCook,
      daysDutySupervisor: daysDutySupervisor,
      daysDutyOfficer: daysDutyOfficer,
      daysDutyOfficerMP: daysDutyOfficerMP,
      daysCCTV1: daysCCTV1,
      daysCCTV2: daysCCTV2,
      daysCCTV3: daysCCTV3,
      daysGateGuard: daysGateGuard,
      homeSleepers: homeSleepers,
      holidays: holidays,
      marketClosedDays: marketClosedDays,
    );
  }

  @override
  Future<void> signDate(Date date) async {
    final sheetName =
        '${monthToPrefixMap[date.month]}${(date.year % 100)}';

    if (!excel.tables.containsKey(sheetName)) {
      throw Exception('Sheet $sheetName not found in Excel file.');
    }
    final sheet = excel.tables[sheetName]!;

    int? dateColIndex;
    for (int col = daysStartCol; col < sheet.maxCols; col++) {
      final d = _parseDateCell(sheet.rows[daysStartRow][col]);
      if (d != null && d == date) {
        dateColIndex = col;
        break;
      }
    }
    if (dateColIndex == null) {
      throw Exception(
          'Date ${date.toReadableString()} not found in sheet $sheetName.');
    }

    int? telosRowIndex;
    for (int row = namesStartRow; row < sheet.maxRows; row++) {
      if (sheet.rows[row][namesStartColumn] == 'ΤΕΛΟΣ') {
        telosRowIndex = row;
        break;
      }
    }
    if (telosRowIndex == null) {
      throw Exception('ΤΕΛΟΣ sentinel row not found in sheet $sheetName.');
    }

    excel.updateCell(sheetName, dateColIndex, telosRowIndex, 'ΥΠΟΓ');

    final dailyPath = _getDailyFolderPath(date);
    await Directory(dailyPath).create(recursive: true);
    await File(p.join(dailyPath, 'excel.xlsx'))
        .writeAsBytes(excel.encode());
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a raw cell value to a [Date], supporting both numeric serial and
  /// ISO string formats.
  Date? _parseDateCell(dynamic cell) {
    if (cell is num) return Date.fromExcelSerial(cell.toInt());
    if (cell is String) {
      try {
        return Date.fromExcelString(cell);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Builds a [Date] → [OtherTasks] map from the in-memory JSON cache.
  Map<Date, OtherTasks> _parseOtherTasksFromCache() {
    final result = <Date, OtherTasks>{};
    _masterJsonMap.forEach((dateString, data) {
      final dt = DateTime.tryParse(dateString);
      if (dt != null) {
        result[Date(day: dt.day, month: dt.month, year: dt.year)] =
            OtherTasks.fromJson(data);
      }
    });
    return result;
  }

  /// Parses a two-column auxiliary sheet (date | name | optional-note) into a
  /// [Date] → [Soldier] map.
  Map<Date, Soldier> _parseSheetToMap(String sheetName) {
    if (!excel.tables.containsKey(sheetName)) return {};
    final sheet = excel.tables[sheetName]!;
    final result = <Date, Soldier>{};

    for (int row = 0; row < sheet.maxRows; row++) {
      final rowData = sheet.rows[row];
      final dateCell = rowData[0];
      final nameCell = rowData[1];
      if (nameCell == null) continue;

      final date = _parseDateCell(dateCell);
      final name = nameCell.toString().trim();
      if (date == null || name.isEmpty) continue;

      final note = rowData.length > 2 ? rowData[2]?.toString().trim() : null;
      result[date] = Soldier(name: name, role: note?.isNotEmpty == true ? note : null);
    }
    return result;
  }

  /// Parses a single-column sheet of soldier names.
  List<Soldier> _parseSimpleList(String sheetName) {
    if (!excel.tables.containsKey(sheetName)) return [];
    final sheet = excel.tables[sheetName]!;
    final result = <Soldier>[];

    for (int row = 0; row < sheet.maxRows; row++) {
      final name = sheet.rows[row][0]?.toString().trim() ?? '';
      if (name.isNotEmpty) result.add(Soldier(name: name));
    }
    return result;
  }

  /// Parses a single-column sheet of dates (numeric serial or ISO string).
  List<Date> _parseHolidays(String sheetName) {
    if (!excel.tables.containsKey(sheetName)) return [];
    final sheet = excel.tables[sheetName]!;
    final result = <Date>[];

    for (int row = 0; row < sheet.maxRows; row++) {
      final cell = sheet.rows[row][0];
      final date = _parseDateCell(cell);
      if (date != null) result.add(date);
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Top-level parsing functions (stateless, used by getStoredData)
// ---------------------------------------------------------------------------

Daily? _processDayColumn(
  TableSheet sheet,
  int colIndex,
  Map<Date, OtherTasks> otherTasksMap,
  Map<Date, Soldier> daysGep,
  Map<Date, Soldier> daysCook,
  Map<Date, Soldier> daysDutySupervisor,
  Map<Date, Soldier> daysDutyOfficer,
  Map<Date, Soldier> daysDutyOfficerMP,
  Map<Date, Soldier> daysCCTV1,
  Map<Date, Soldier> daysCCTV2,
  Map<Date, Soldier> daysCCTV3,
  Map<Date, Soldier> daysGateGuard,
  List<Date> holidays,
  List<Date> marketClosedDays,
) {
  final dayCell = sheet.rows[daysStartRow][colIndex];
  if (dayCell is! num && dayCell is! String) return null;

  Date? date;
  if (dayCell is String) {
    try {
      date = Date.fromExcelString(dayCell);
    } catch (_) {
      return null;
    }
  } else if (dayCell is num) {
    date = Date.fromExcelSerial(dayCell.toInt());
  }
  if (date == null) return null;

  var currentProgram = const Program();
  final manpower = <Soldier>[];
  bool isSigned = false;

  for (int row = namesStartRow; row < sheet.maxRows; row++) {
    final nameCell = sheet.rows[row][namesStartColumn];
    if (nameCell == null || nameCell == '') continue;

    final name = nameCell.trim();
    if (name == 'ΤΕΛΟΣ') {
      isSigned = sheet.rows[row][colIndex] == 'ΥΠΟΓ';
      break;
    }

    final soldier = _readSoldier(sheet.rows[row], name);
    final statusCell = sheet.rows[row][colIndex];

    if (statusCell is String?) {
      final code = statusCell?.trim() ?? '';
      currentProgram =
          _updateProgramWithAssignment(currentProgram, code, soldier);
      if (code != 'ΤΕΛΟΣ') manpower.add(soldier);
    } else {
      manpower.add(soldier);
    }
  }

  var tasksForToday = otherTasksMap[date] ?? const OtherTasks();
  tasksForToday = tasksForToday.copyWith(
    execGep: daysGep[date],
    execCook: daysCook[date],
    execDutySupervisor: daysDutySupervisor[date],
    execDutyOfficer: daysDutyOfficer[date],
    execDutyOfficerMP: daysDutyOfficerMP[date],
    execCCTV1: daysCCTV1[date],
    execCCTV2: daysCCTV2[date],
    execCCTV3: daysCCTV3[date],
    execGateGuard: daysGateGuard[date],
  );

  return Daily(
    date: date,
    program: currentProgram,
    otherTasks: tasksForToday,
    manpower: manpower,
    isSigned: isSigned,
    isHoliday: holidays.contains(date),
    isMilitaryMarketClosed: marketClosedDays.contains(date),
  );
}

/// Reads all soldier fields from a single spreadsheet row.
Soldier _readSoldier(List<dynamic> row, String name) {
  String _str(int col) => row.length > col ? (row[col]?.toString().trim() ?? '') : '';
  String? _nullable(int col) {
    final v = _str(col);
    return v.isNotEmpty ? v : null;
  }

  String role = _str(rolesStartColumn);
  if (role.isEmpty) role = 'ΦΥΛ';

  String? phoneNumber;
  final phoneCell = row.length > phoneNumberStartColumn
      ? row[phoneNumberStartColumn]
      : null;
  if (phoneCell is num) {
    phoneNumber = phoneCell.toInt().toString();
  } else if (phoneCell != null) {
    final s = phoneCell.toString().trim();
    phoneNumber = s.isNotEmpty ? s : null;
  }

  String? dateOfArrival;
  final doaCell = row.length > dateOfArrivalStartColumn
      ? row[dateOfArrivalStartColumn]
      : null;
  if (doaCell is num) {
    try {
      dateOfArrival = Date.fromExcelSerial(doaCell.toInt()).toReadableString();
    } catch (_) {
      dateOfArrival = doaCell.toString();
    }
  } else if (doaCell != null) {
    final s = doaCell.toString().trim();
    dateOfArrival = s.isNotEmpty ? s : null;
  }

  return Soldier(
    name: name,
    role: role,
    id: _nullable(iDStartColumn),
    phoneNumber: phoneNumber,
    unit: _nullable(unitStartColumn),
    ability: _nullable(physicalAbilityStartColumn),
    note: _nullable(notesStartColumn),
    rank: _nullable(rankStartColumn),
    esso: _nullable(essoStartColumn),
    dateofArival: dateOfArrival,
  );
}

Program _updateProgramWithAssignment(
  Program prog,
  String code,
  Soldier soldier,
) {
  switch (code) {
    case 'ΓΕΠ':
      return prog.copyWith(gep: soldier);
    case 'ΕΣΤ':
      return prog.copyWith(kitchen: soldier);
    case 'ΘΑΛ1':
      return prog.copyWith(dormGuard1: soldier);
    case 'ΘΑΛ2':
      return prog.copyWith(dormGuard2: soldier);
    case 'ΘΑΛ3':
      return prog.copyWith(dormGuard3: soldier);
    case 'ΛΥΛ':
      return prog.copyWith(dutySergeant: soldier);
    case 'ΔΠΒ':
      return prog.copyWith(dpvCanteen: soldier);
    case 'ΣΚ1':
      return prog.post1 == null
          ? prog.copyWith(post1: soldier)
          : prog.copyWith(hiddenPost1: soldier);
    case 'ΣΚ2':
      return prog.post2 == null
          ? prog.copyWith(post2: soldier)
          : prog.copyWith(hiddenPost2: soldier);
    case 'ΣΚ3':
      return prog.post3 == null
          ? prog.copyWith(post3: soldier)
          : prog.copyWith(hiddenPost3: soldier);
    case 'ΔΙΑΘ':
      return prog.copyWith(detached: [...prog.detached, soldier]);
    case 'ΑΔΕΙΑ':
      return prog.copyWith(onLeave: [...prog.onLeave, soldier]);
    case 'ΕΥ':
      return prog.copyWith(exempt: [...prog.exempt, soldier]);
    case 'ΚΥΛ':
      return prog.copyWith(
          divisionCanteen: [...prog.divisionCanteen, soldier]);
    case 'ΕΞ':
      return prog.copyWith(exits: [...prog.exits, soldier]);
    default:
      return prog;
  }
}
