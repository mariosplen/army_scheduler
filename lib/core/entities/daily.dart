import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/other_tasks.dart';
import 'package:ls_ypiresies/core/entities/program.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';

part 'daily.g.dart';

@CopyWith()
class Daily extends Equatable {
  final Program program;
  final OtherTasks otherTasks;
  final bool isHoliday;
  final bool isMilitaryMarketClosed;
  final bool isSigned;
  final Date date;
  final List<Soldier> manpower;

  bool get isWeekend =>
      date.toDateTime().weekday == 6 || date.toDateTime().weekday == 7;

  bool get isSunday => date.toDateTime().weekday == 7;

  bool get isSaturday => date.toDateTime().weekday == 6;

  bool get isMonday => date.toDateTime().weekday == 1;

  /// Soldiers who cannot leave the base (assigned to a service, on leave, or exempt).
  List<Soldier> get cantLeaveBase {
    final assigned = {
      program.post1,
      program.hiddenPost1,
      program.post2,
      program.hiddenPost2,
      program.post3,
      program.hiddenPost3,
      program.dormGuard1,
      program.dormGuard2,
      program.dormGuard3,
      program.dutySergeant,
      program.kitchen,
      program.gep,
      ...program.onLeave,
      ...program.exempt,
    }.whereType<Soldier>();

    return manpower.where((s) => assigned.contains(s)).toList();
  }

  /// Soldiers who are free to leave the base.
  List<Soldier> get canLeaveBase {
    final assigned = {
      program.post1,
      program.hiddenPost1,
      program.post2,
      program.hiddenPost2,
      program.post3,
      program.hiddenPost3,
      program.dormGuard1,
      program.dormGuard2,
      program.dormGuard3,
      program.dutySergeant,
      program.kitchen,
      program.gep,
      ...program.onLeave,
      ...program.exempt,
      ...program.detached,
    }.whereType<Soldier>();

    return manpower.where((s) => !assigned.contains(s)).toList();
  }

  /// Soldiers not assigned to any primary service (available for secondary tasks).
  List<Soldier> get totalFree {
    final assigned = {
      program.post1,
      program.hiddenPost1,
      program.post2,
      program.hiddenPost2,
      program.post3,
      program.hiddenPost3,
      program.dormGuard1,
      program.dormGuard2,
      program.dormGuard3,
      program.dutySergeant,
      program.kitchen,
      program.gep,
      ...program.onLeave,
      ...program.exempt,
      ...program.detached,
    }.whereType<Soldier>();

    return manpower.where((s) => !assigned.contains(s)).toList();
  }

  /// Soldiers eligible to be assigned as a reserve (κωλυόμενος).
  List<Soldier> get canBeAssignedReserve {
    final assigned = {
      program.post1,
      program.hiddenPost1,
      program.post2,
      program.hiddenPost2,
      program.post3,
      program.hiddenPost3,
      program.dormGuard1,
      program.dormGuard2,
      program.dormGuard3,
      program.kitchen,
      program.gep,
      otherTasks.kpsm,
      ...program.onLeave,
      ...program.exempt,
      ...program.detached,
    }.whereType<Soldier>();

    return manpower.where((s) => !assigned.contains(s)).toList();
  }

  /// Soldiers eligible to be assigned to a service or cleaning duty.
  List<Soldier> get canBeAssignedToServiceOrCleaning {
    final assigned = {
      ...program.onLeave,
      ...program.exempt,
      ...program.detached,
    }.whereType<Soldier>();

    return manpower.where((s) => !assigned.contains(s)).toList();
  }

  const Daily({
    required this.program,
    required this.otherTasks,
    required this.date,
    this.isHoliday = false,
    this.isMilitaryMarketClosed = false,
    this.isSigned = false,
    this.manpower = const [],
  });

  factory Daily.empty(Date date) {
    return Daily(
      program: const Program(),
      otherTasks: const OtherTasks(),
      date: date,
    );
  }

  @override
  List<Object?> get props => [
        program,
        otherTasks,
        isHoliday,
        isMilitaryMarketClosed,
        isSigned,
        date,
        manpower,
      ];
}
