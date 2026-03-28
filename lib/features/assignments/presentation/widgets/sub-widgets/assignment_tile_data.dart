import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/core/enums/slot.dart';
import 'package:ls_ypiresies/core/theme/app_colors.dart';

class AssignmentTileData extends Equatable {
  final List<Soldier> soldiers;
  final String? title;
  final String? reserveText;
  final Widget? leading;
  final bool isEditable;
  final VoidCallback? onAutoFill;
  final VoidCallback? onAddReserve;
  final VoidCallback? onDeleteReserve;
  final VoidCallback? onDeleteAll;
  final ValueChanged<Soldier>? onAccept;
  final void Function({Soldier? soldier})? onDelete;

  const AssignmentTileData._({
    this.soldiers = const [],
    this.title,
    this.reserveText,
    this.leading,
    this.isEditable = true,
    this.onAutoFill,
    this.onAddReserve,
    this.onDeleteReserve,
    this.onDeleteAll,
    this.onAccept,
    this.onDelete,
  });

  factory AssignmentTileData.factory({
    required Slot slot,
    required Daily daily,
    Daily? previousDaily, // Added parameter
    String time = '08:00',
    void Function({
      Soldier? soldier,
      required Slot slot,
      bool isAdding,
    })? onAssign,
    void Function(Slot slot)? onAddReserve, // Changed: Now accepts a callback
  }) {
    return AssignmentTileData._(
      soldiers: _getSoldiers(slot, daily),
      title: _getTitle(slot, time, daily),
      leading: _getLeading(slot),
      onAddReserve: _getOnAddReserve(slot, onAddReserve),
      onAutoFill: _getOnAutoFill(slot, onAssign, daily, previousDaily),
      reserveText: _getReserveText(slot, daily),
      isEditable: _getIsEditable(slot, daily),
      onAccept: _getOnAccept(slot, onAssign),
      onDelete: _getOnDelete(slot, onAssign),
      onDeleteAll: _getOnDeleteAll(slot, onAssign),
      onDeleteReserve: _getOnDeleteReserve(slot, onAssign),
    );
  }

  // Refactored: Standard switch statement
  static Slot? getReserveSlot(Slot slot) {
    switch (slot) {
      case Slot.post1:
        return Slot.reservePost1;
      case Slot.post2:
        return Slot.reservePost2;
      case Slot.post3:
        return Slot.reservePost3;
      case Slot.hiddenPost1:
        return Slot.reserveHiddenPost1;
      case Slot.hiddenPost2:
        return Slot.reserveHiddenPost2;
      case Slot.hiddenPost3:
        return Slot.reserveHiddenPost3;
      case Slot.dormGuard1:
        return Slot.reserveDormGuard1;
      case Slot.dormGuard2:
        return Slot.reserveDormGuard2;
      case Slot.dormGuard3:
        return Slot.reserveDormGuard3;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        soldiers,
        title,
        reserveText,
        leading,
        isEditable,
        onAutoFill,
        onAddReserve,
        onDeleteReserve,
        onDeleteAll,
        onAccept,
        onDelete,
      ];
}

// Refactored: Standard switch statement
List<Soldier> _getSoldiers(Slot slot, Daily daily) {
  switch (slot) {
    case Slot.flagRising:
      return daily.otherTasks.flagRising;
    case Slot.flagLowering:
      return daily.otherTasks.flagLowering;
    case Slot.post1:
      return [if (daily.program.post1 != null) daily.program.post1!];
    case Slot.post2:
      return [if (daily.program.post2 != null) daily.program.post2!];
    case Slot.post3:
      return [if (daily.program.post3 != null) daily.program.post3!];
    case Slot.hiddenPost1:
      return [
        if (daily.program.hiddenPost1 != null) daily.program.hiddenPost1!,
      ];
    case Slot.hiddenPost2:
      return [
        if (daily.program.hiddenPost2 != null) daily.program.hiddenPost2!,
      ];
    case Slot.hiddenPost3:
      return [
        if (daily.program.hiddenPost3 != null) daily.program.hiddenPost3!,
      ];
    case Slot.dormGuard1:
      return [
        if (daily.program.dormGuard1 != null) daily.program.dormGuard1!,
      ];
    case Slot.dormGuard2:
      return [
        if (daily.program.dormGuard2 != null) daily.program.dormGuard2!,
      ];
    case Slot.dormGuard3:
      return [
        if (daily.program.dormGuard3 != null) daily.program.dormGuard3!,
      ];
    case Slot.gep:
      return [
        if (daily.program.gep != null)
          daily.program.gep!
        else if (daily.otherTasks.execGep != null)
          daily.otherTasks.execGep!,
      ];
    case Slot.kitchen:
      return [
        if (daily.program.kitchen != null) daily.program.kitchen!,
      ];
    case Slot.dutySergeant:
      return [
        if (daily.program.dutySergeant != null) daily.program.dutySergeant!,
      ];
    case Slot.dpvCanteen:
      return [
        if (daily.program.dpvCanteen != null) daily.program.dpvCanteen!,
      ];
    case Slot.divisionCanteen:
      return daily.program.divisionCanteen;
    case Slot.detached:
      return daily.program.detached;
    case Slot.kpsm:
      return [if (daily.otherTasks.kpsm != null) daily.otherTasks.kpsm!];
    case Slot.cleanBinArea:
      return [
        if (daily.otherTasks.cleanBinArea != null)
          daily.otherTasks.cleanBinArea!,
      ];
    case Slot.cleanDormGuardArea:
      return [
        if (daily.otherTasks.cleanDormGuardArea != null)
          daily.otherTasks.cleanDormGuardArea!,
      ];
    case Slot.cleanSupervisorArea:
      return daily.otherTasks.cleanSupervisorArea;
    case Slot.cleanDivisionArea:
      return daily.otherTasks.cleanDivisionArea;
    case Slot.cleanToiletsArea:
      return daily.otherTasks.cleanToiletsArea;
    case Slot.cleanBarracksArea:
      return daily.otherTasks.cleanBarracksArea;
    case Slot.passengerForFoodLunch:
      return [
        if (daily.otherTasks.passengerForFoodLunch != null)
          daily.otherTasks.passengerForFoodLunch!,
      ];
    case Slot.passengerForFoodDinner:
      return [
        if (daily.otherTasks.passengerForFoodDinner != null)
          daily.otherTasks.passengerForFoodDinner!,
      ];
    case Slot.foodTransferLunch:
      return daily.otherTasks.foodTransferLunch;
    case Slot.foodTransferDinner:
      return daily.otherTasks.foodTransferDinner;
    case Slot.onLeave:
      return daily.program.onLeave;
    case Slot.exempt:
      return daily.program.exempt;
    case Slot.free:
      return daily.canLeaveBase;
    default:
      return <Soldier>[];
  }
}

VoidCallback? _getOnDeleteAll(
  Slot slot,
  void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign,
) {
  return onAssign == null
      ? null
      : () {
          onAssign(
            slot: slot,
            isAdding: false,
          );
        };
}

VoidCallback? _getOnDeleteReserve(
  Slot slot,
  void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign,
) {
  final reserveSlot = AssignmentTileData.getReserveSlot(slot);

  if (onAssign == null || reserveSlot == null) {
    return null;
  }
  return () {
    onAssign(
      slot: reserveSlot,
      isAdding: false,
    );
  };
}

VoidCallback? _getOnAutoFill(
  Slot slot,
  void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign,
  Daily daily,
  Daily? previousDaily, // Added parameter
) {
  if (onAssign == null) {
    return null;
  }

  switch (slot) {
    case Slot.passengerForFoodDinner:
      // 1. Calculate the value first
      final dormGuard3 = daily.program.dormGuard3;

      // 2. Check condition immediately. If false, return null.
      if (dormGuard3 == null) {
        return null;
      }

      // 3. Return the callback knowing the data is valid
      return () {
        onAssign(
          soldier: dormGuard3,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.cleanSupervisorArea:
      final post1 = daily.program.post1;
      final hiddenPost1 = daily.program.hiddenPost1;
      final soldiersToAdd = [post1, hiddenPost1].whereType<Soldier>().toList();

      // Check condition immediately
      if (soldiersToAdd.length != 2) {
        return null;
      }

      return () {
        for (var soldier in soldiersToAdd) {
          onAssign(
            soldier: soldier,
            slot: slot,
            isAdding: true,
          );
        }
      };

    case Slot.dpvCanteen:
      final manpower = daily.manpower;
      final soldier = manpower.firstWhereOrNull(
        (s) => s.role == 'ΔΠΒ',
      );
      if (soldier == null) {
        return null;
      }
      return () {
        onAssign(
          soldier: soldier,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.kpsm:
      final soldiers = daily.manpower;
      final soldier = soldiers.firstWhereOrNull(
        (s) =>
            s.role == 'ΚΨΜ' &&
            !daily.program.onLeave.contains(s) &&
            !daily.program.exempt.contains(s),
      );
      if (soldier == null) {
        return null;
      }
      return () {
        onAssign(
          soldier: soldier,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.divisionCanteen:
      final soldiers = daily.manpower;
      final divisionCanteenSoldiers =
          soldiers.where((s) => s.role == 'ΚΥΛΙΚΕΙΟ').toList();
      if (divisionCanteenSoldiers.isEmpty) return null;
      return () {
        for (var soldier in divisionCanteenSoldiers) {
          // we must check if he is not on leave or exempt

          final isOnLeaveOrExempt = daily.program.onLeave.contains(soldier) ||
              daily.program.exempt.contains(soldier);
          if (!isOnLeaveOrExempt) {
            onAssign(
              soldier: soldier,
              slot: slot,
              isAdding: true,
            );
          }
        }
      };

    case Slot.cleanBinArea:
      final binCleaner = daily.program.gep;
      if (binCleaner == null) {
        return null;
      }
      return () {
        onAssign(
          soldier: binCleaner,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.passengerForFoodLunch:
      final dormGuard1 = daily.program.dormGuard1;
      final reserveDormGuard1 = daily.otherTasks.reserveDormGuard1;
      final soldier = reserveDormGuard1 ?? dormGuard1;
      if (soldier == null) {
        return null;
      }
      return () {
        onAssign(
          soldier: soldier,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.foodTransferDinner:
      final cook = daily.program.kitchen;
      if (cook == null) {
        return null;
      }
      return () {
        onAssign(
          soldier: cook,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.cleanDormGuardArea:
      // Updated Logic: Use previous day's 3rd Dorm Guard
      if (previousDaily == null) return null;

      final dormGuard3 = previousDaily.program.dormGuard3;
      final reserveDormGuard3 = previousDaily.otherTasks.reserveDormGuard3;
      // Use reserve if it exists, otherwise the regular guard
      final soldier = reserveDormGuard3 ?? dormGuard3;

      // Check condition immediately
      if (soldier == null) {
        return null;
      }

      return () {
        onAssign(
          soldier: soldier,
          slot: slot,
          isAdding: true,
        );
      };

    case Slot.foodTransferLunch:
      final reservePost2 = daily.otherTasks.reservePost2;
      final post2 = daily.program.post2;
      final soldier1 = reservePost2 ?? post2;

      final reserveHiddenPost2 = daily.otherTasks.reserveHiddenPost2;
      final hiddenPost2 = daily.program.hiddenPost2;
      final soldier2 = reserveHiddenPost2 ?? hiddenPost2;

      final soldiersToAdd = [soldier1, soldier2].whereType<Soldier>().toList();

      // Check condition immediately
      if (soldiersToAdd.length != 2) {
        return null;
      }

      return () {
        for (var soldier in soldiersToAdd) {
          onAssign(
            soldier: soldier,
            slot: slot,
            isAdding: true,
          );
        }
      };

    default:
      return null;
  }
}

ValueChanged<Soldier>? _getOnAccept(
  Slot slot,
  void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign,
) {
  return onAssign == null
      ? null
      : (Soldier soldier) => onAssign(
            soldier: soldier,
            slot: slot,
          );
}

void Function({Soldier? soldier})? _getOnDelete(
  Slot slot,
  void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign,
) {
  return onAssign == null
      ? null
      : ({Soldier? soldier}) => onAssign(
            soldier: soldier,
            slot: slot,
            isAdding: false,
          );
}

// Refactored: Standard switch with fall-through
VoidCallback? _getOnAddReserve(
    Slot slot, void Function(Slot slot)? onAddReserve) {
  bool canHaveReserve;
  switch (slot) {
    case Slot.post1:
    case Slot.post2:
    case Slot.post3:
    case Slot.hiddenPost1:
    case Slot.hiddenPost2:
    case Slot.hiddenPost3:
    case Slot.dormGuard1:
    case Slot.dormGuard2:
    case Slot.dormGuard3:
      canHaveReserve = true;
      break;
    default:
      canHaveReserve = false;
      break;
  }

  if (!canHaveReserve || onAddReserve == null) return null;

  return () => onAddReserve(slot);
}

bool _getIsEditable(Slot slot, Daily daily) {
  if ([Slot.exempt, Slot.free, Slot.onLeave, Slot.detached].contains(slot)) {
    return false;
  }
  return !daily.isSigned;
}

// Refactored: Standard switch statement
String? _getReserveText(Slot slot, Daily daily) {
  switch (slot) {
    case Slot.post1:
      return daily.otherTasks.reservePost1?.name;
    case Slot.post2:
      return daily.otherTasks.reservePost2?.name;
    case Slot.post3:
      return daily.otherTasks.reservePost3?.name;
    case Slot.hiddenPost1:
      return daily.otherTasks.reserveHiddenPost1?.name;
    case Slot.hiddenPost2:
      return daily.otherTasks.reserveHiddenPost2?.name;
    case Slot.hiddenPost3:
      return daily.otherTasks.reserveHiddenPost3?.name;
    case Slot.dormGuard1:
      return daily.otherTasks.reserveDormGuard1?.name;
    case Slot.dormGuard2:
      return daily.otherTasks.reserveDormGuard2?.name;
    case Slot.dormGuard3:
      return daily.otherTasks.reserveDormGuard3?.name;
    default:
      return null;
  }
}

// Refactored: Standard switch statement
Icon? _getLeading(Slot slot) {
  IconData? iconData;
  switch (slot) {
    case Slot.flagRising:
      iconData = Icons.wb_sunny_outlined;
      break;
    case Slot.flagLowering:
      iconData = Icons.nightlight_round;
      break;
    case Slot.cleanDivisionArea:
      iconData = Icons.account_balance;
      break;
    case Slot.cleanToiletsArea:
      iconData = Icons.wc_sharp;
      break;
    case Slot.cleanBarracksArea:
      iconData = Icons.house;
      break;
    case Slot.cleanBinArea:
      iconData = Icons.delete;
      break;
    case Slot.cleanDormGuardArea:
      iconData = Icons.cleaning_services;
      break;
    case Slot.cleanSupervisorArea:
      iconData = Icons.cell_tower;
      break;
    case Slot.kitchen:
      iconData = Icons.restaurant;
      break;
    case Slot.foodTransferDinner:
    case Slot.foodTransferLunch:
      iconData = Icons.signpost;
      break;
    case Slot.passengerForFoodDinner:
    case Slot.passengerForFoodLunch:
      iconData = Icons.local_shipping;
      break;
    case Slot.gep:
      iconData = Icons.computer;
      break;
    case Slot.dutySergeant:
      iconData = Icons.military_tech_rounded;
      break;
    default:
      iconData = null;
  }

  if (iconData == null) {
    return null;
  }

  Color color;
  if (slot == Slot.flagRising || slot == Slot.flagLowering) {
    color = AppColors.orange;
  } else {
    color = AppColors.purple;
  }

  return Icon(
    iconData,
    size: 19,
    color: color,
  );
}

// Refactored: Standard switch statement with fall-through
String _getTitle(Slot slot, String time, Daily daily) {
  switch (slot) {
    case Slot.flagRising:
      return 'ΕΠΑΡΣΗ ΣΗΜΑΙΑΣ - $time';
    case Slot.flagLowering:
      return 'ΥΠΟΣΤΟΛΗ ΣΗΜΑΙΑΣ - $time';
    case Slot.post1:
    case Slot.post2:
    case Slot.post3:
      return 'ΦΑΝΕΡΟΣ ΣΚΟΠΟΣ';
    case Slot.hiddenPost1:
    case Slot.hiddenPost2:
    case Slot.hiddenPost3:
      return 'ΚΡΥΦΟΣ ΣΚΟΠΟΣ';
    case Slot.dormGuard1:
    case Slot.dormGuard2:
    case Slot.dormGuard3:
      return 'ΘΑΛΑΜΟΦΥΛΑΚΑΣ';
    case Slot.gep:
      return 'ΓΕΠ';
    case Slot.kitchen:
      return 'ΕΣΤΙΑΤΟΡΑΣ';
    case Slot.dutySergeant:
      return 'ΛΟΧΙΑΣ ΥΠΗΡΕΣΙΑΣ';
    case Slot.dpvCanteen:
      return 'ΚΥΛΙΚΕΙΟ ΔΠΒ';
    case Slot.divisionCanteen:
      return 'ΚΥΛΙΚΕΙΟ ΜΕΡΑΡΧΙΑΣ';
    case Slot.kpsm:
      return 'ΚΨΜ';
    case Slot.cleanBinArea:
      return 'ΚΑΘ. ΚΑΔΟΣ - ${daily.isHoliday || daily.isWeekend ? '(08:15-08:30)' : '(06:45-07:00)'}';
    case Slot.cleanDormGuardArea:
      return 'ΚΑΘ. ΧΩΡΟΥ ΘΑΛ - ${daily.isHoliday || daily.isWeekend ? '(08:15-08:30)' : '(06:45-07:00)'}';
    case Slot.cleanSupervisorArea:
      return 'ΚΑΘ. ΕΠΟΠΤΕΙΟ - ${daily.isHoliday || daily.isWeekend ? '(08:00-08:15)' : '(06:20-06:35)'}';
    case Slot.cleanDivisionArea:
      return 'ΚΑΘ. ΜΕΡΑΡΧΙΑ - ${daily.isHoliday || daily.isWeekend ? '(14:00)' : '(16:00)'}';
    case Slot.cleanToiletsArea:
      return 'ΚΑΘ. ΤΟΥΑΛΕΤΕΣ - ${daily.isHoliday || daily.isWeekend ? '(08:15-08:30)' : '(06:45-07:00)'}';
    case Slot.cleanBarracksArea:
      return 'ΚΑΘ. ΘΑΛΑΜΟΙ - ${daily.isHoliday || daily.isWeekend ? '(08:15-08:30)' : '(06:45-07:00)'}';
    case Slot.passengerForFoodLunch:
      return 'ΚΙΝΗΣΗ ΓΙΑ ΦΑΓΗΤΟ (13:00)';
    case Slot.passengerForFoodDinner:
      return 'ΚΙΝΗΣΗ ΓΙΑ ΦΑΓΗΤΟ (18:00)';
    case Slot.foodTransferLunch:
      return 'ΔΙΑΝΟΜΗ ΦΑΓΗΤΟΥ (13:00)';
    case Slot.foodTransferDinner:
      return 'ΔΙΑΝΟΜΗ ΦΑΓΗΤΟΥ (18:00)';
    case Slot.detached:
      return 'ΣΕ ΔΙΑΘΕΣΗ';
    case Slot.reservePost1:
    case Slot.reservePost2:
    case Slot.reservePost3:
    case Slot.reserveHiddenPost1:
    case Slot.reserveHiddenPost2:
    case Slot.reserveHiddenPost3:
    case Slot.reserveDormGuard1:
    case Slot.reserveDormGuard2:
    case Slot.reserveDormGuard3:
      return 'ΚΟΛΥΩΜΕΝΟ';
    case Slot.onLeave:
      return 'ΣΕ ΑΔΕΙΑ';
    case Slot.exempt:
      return 'ΕΛΕΥΘΕΡΟΙ ΥΠΗΡΕΣΙΑΣ';
    case Slot.free:
      return 'ΕΞΟΔΟΥΧΟΙ - ${daily.isHoliday || daily.isWeekend ? '(10:00-22:30)' : '(15:00-22:30)'}';
    default:
      return '';
  }
}
