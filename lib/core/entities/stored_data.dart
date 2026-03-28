import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/other_tasks.dart';
import 'package:ls_ypiresies/core/entities/program.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';

/// Holds all persisted data loaded at startup — daily assignments across the
/// full spreadsheet, auxiliary officer rotation sheets, home-sleeper list,
/// holidays, and market-closed days.
class StoredData extends Equatable {
  final Map<Date, Daily> assignments;
  final Map<Date, Soldier> daysGep;
  final Map<Date, Soldier> daysCook;
  final Map<Date, Soldier> daysDutySupervisor;
  final Map<Date, Soldier> daysDutyOfficer;
  final Map<Date, Soldier> daysDutyOfficerMP;
  final Map<Date, Soldier> daysCCTV1;
  final Map<Date, Soldier> daysCCTV2;
  final Map<Date, Soldier> daysCCTV3;
  final Map<Date, Soldier> daysGateGuard;
  final List<Soldier> homeSleepers;
  final List<Date> holidays;
  final List<Date> marketClosedDays;

  const StoredData({
    this.assignments = const {},
    this.daysGep = const {},
    this.daysDutySupervisor = const {},
    this.daysDutyOfficer = const {},
    this.daysDutyOfficerMP = const {},
    this.daysCCTV1 = const {},
    this.daysCCTV2 = const {},
    this.daysCCTV3 = const {},
    this.daysGateGuard = const {},
    this.daysCook = const {},
    this.homeSleepers = const [],
    this.holidays = const [],
    this.marketClosedDays = const [],
  });

  /// Builds a [Daily] for [date] by merging stored assignment data with
  /// auxiliary officer assignments from the rotation sheets.
  Daily getDailyFor(Date date) {
    final dailyProgram = assignments[date]?.program;
    final baseOtherTasks = assignments[date]?.otherTasks ?? const OtherTasks();

    return Daily(
      date: date,
      program: Program(
        post1: dailyProgram?.post1,
        post2: dailyProgram?.post2,
        post3: dailyProgram?.post3,
        hiddenPost1: dailyProgram?.hiddenPost1,
        hiddenPost2: dailyProgram?.hiddenPost2,
        hiddenPost3: dailyProgram?.hiddenPost3,
        dormGuard1: dailyProgram?.dormGuard1,
        dormGuard2: dailyProgram?.dormGuard2,
        dormGuard3: dailyProgram?.dormGuard3,
        dpvCanteen: dailyProgram?.dpvCanteen,
        kitchen: dailyProgram?.kitchen,
        dutySergeant: dailyProgram?.dutySergeant,
        gep: dailyProgram?.gep,
        divisionCanteen: dailyProgram?.divisionCanteen ?? [],
        detached: dailyProgram?.detached ?? [],
        onLeave: dailyProgram?.onLeave ?? [],
        exempt: dailyProgram?.exempt ?? [],
        exits: dailyProgram?.exits ?? [],
      ),
      otherTasks: baseOtherTasks.copyWith(
        execGep: daysGep[date],
        execCook: daysCook[date],
        execDutySupervisor: daysDutySupervisor[date],
        execDutyOfficer: daysDutyOfficer[date],
        execDutyOfficerMP: daysDutyOfficerMP[date],
        execCCTV1: daysCCTV1[date],
        execCCTV2: daysCCTV2[date],
        execCCTV3: daysCCTV3[date],
        execGateGuard: daysGateGuard[date],
      ),
      manpower: assignments[date]?.manpower ?? [],
      isSigned: assignments[date]?.isSigned ?? false,
      isHoliday: holidays.contains(date),
      isMilitaryMarketClosed: marketClosedDays.contains(date),
    );
  }

  int getTotalServicesForMonth({
    required Soldier soldier,
    required Date date,
    bool includeFuture = true,
  }) {
    int total = 0;
    assignments.forEach((assignedDate, daily) {
      if (assignedDate.month != date.month || assignedDate.year != date.year) {
        return;
      }
      if (!includeFuture &&
          assignedDate.toDateTime().isAfter(date.toDateTime()) &&
          assignedDate != date) {
        return;
      }

      final p = daily.program;
      if (p.gep == soldier) total++;
      if (p.dormGuard1 == soldier) total++;
      if (p.dormGuard2 == soldier) total++;
      if (p.dormGuard3 == soldier) total++;
      if (p.post1 == soldier) total++;
      if (p.post2 == soldier) total++;
      if (p.post3 == soldier) total++;
      if (p.hiddenPost1 == soldier) total++;
      if (p.hiddenPost2 == soldier) total++;
      if (p.hiddenPost3 == soldier) total++;
      if (p.dutySergeant == soldier) total++;
      if (p.kitchen == soldier) total++;
    });
    return total;
  }

  int getTotalReservesForMonth({
    required Soldier soldier,
    required Date date,
    bool includeFuture = true,
  }) {
    int total = 0;
    assignments.forEach((assignedDate, daily) {
      if (assignedDate.month != date.month || assignedDate.year != date.year) {
        return;
      }
      if (!includeFuture &&
          assignedDate.toDateTime().isAfter(date.toDateTime()) &&
          assignedDate != date) {
        return;
      }

      final o = daily.otherTasks;
      if (o.reservePost1 == soldier) total++;
      if (o.reserveHiddenPost1 == soldier) total++;
      if (o.reservePost2 == soldier) total++;
      if (o.reserveHiddenPost2 == soldier) total++;
      if (o.reservePost3 == soldier) total++;
      if (o.reserveHiddenPost3 == soldier) total++;
      if (o.reserveDormGuard1 == soldier) total++;
      if (o.reserveDormGuard2 == soldier) total++;
      if (o.reserveDormGuard3 == soldier) total++;
    });
    return total;
  }

  /// Returns how many consecutive days [soldier] has been unable to leave the
  /// base, counting backwards from the day before [date].
  int getDaysSinceLastExit({required Soldier soldier, required Date date}) {
    int days = 0;
    Date current =
        Date.fromDateTime(date.toDateTime().subtract(const Duration(days: 1)));

    while (true) {
      final daily = assignments[current];
      final cantLeave = daily?.cantLeaveBase ?? [];
      if (!cantLeave.contains(soldier)) break;
      days++;
      current = Date.fromDateTime(
          current.toDateTime().subtract(const Duration(days: 1)));
    }
    return days;
  }

  int getTotalLeavesForMonth({
    required Soldier soldier,
    required Date date,
    bool includeFuture = true,
  }) {
    int total = 0;
    assignments.forEach((assignedDate, daily) {
      if (assignedDate.month != date.month || assignedDate.year != date.year) {
        return;
      }
      if (!includeFuture &&
          assignedDate.toDateTime().isAfter(date.toDateTime()) &&
          assignedDate != date) {
        return;
      }
      if (daily.program.onLeave.contains(soldier)) total++;
    });
    return total;
  }

  int getTotalExitsForMonth({
    required Soldier soldier,
    required Date date,
    bool includeFuture = true,
  }) {
    int total = 0;
    assignments.forEach((assignedDate, daily) {
      if (assignedDate.month != date.month || assignedDate.year != date.year) {
        return;
      }
      if (!includeFuture &&
          assignedDate.toDateTime().isAfter(date.toDateTime()) &&
          assignedDate != date) {
        return;
      }
      if (daily.program.exits.contains(soldier)) total++;
    });
    return total;
  }

  int getTotalServicesFor(Soldier soldier) {
    int total = 0;
    assignments.forEach((_, daily) {
      final p = daily.program;
      if (p.gep == soldier) total++;
      if (p.dormGuard1 == soldier) total++;
      if (p.dormGuard2 == soldier) total++;
      if (p.dormGuard3 == soldier) total++;
      if (p.post1 == soldier) total++;
      if (p.post2 == soldier) total++;
      if (p.post3 == soldier) total++;
      if (p.hiddenPost1 == soldier) total++;
      if (p.hiddenPost2 == soldier) total++;
      if (p.hiddenPost3 == soldier) total++;
    });
    return total;
  }

  int getTotalLeavesFor(Soldier soldier) {
    int total = 0;
    assignments.forEach((_, daily) {
      if (daily.program.onLeave.contains(soldier)) total++;
    });
    return total;
  }

  @override
  List<Object?> get props => [
        assignments,
        daysGep,
        daysDutySupervisor,
        daysDutyOfficer,
        daysDutyOfficerMP,
        daysCCTV1,
        daysCCTV2,
        daysCCTV3,
        daysGateGuard,
        daysCook,
        homeSleepers,
        holidays,
        marketClosedDays,
      ];
}
