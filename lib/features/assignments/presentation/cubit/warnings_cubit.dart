import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';

part 'warnings_state.dart';

/// Abstract base class for a scheduling validation rule.
///
/// Each rule receives the current day's [Daily] and the full map of all
/// available dailies. It returns a localised warning string if the rule is
/// violated, or `null` if everything is fine.
abstract class WarningRule {
  String? check(Daily current, Map<Date, Daily> allDailies);
}

// ---------------------------------------------------------------------------
// Guard-post rules
// ---------------------------------------------------------------------------

/// A soldier who was Post 3 (Σκοπός 3ο Νούμερο) yesterday cannot be
/// Post 1 today without a gap — they would serve 4 hours back-to-back.
class Post3ToPost1Rule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];
    final prevPost3 = previous?.program.post3;
    final prevHiddenPost3 = previous?.program.hiddenPost3;

    final matched = [prevPost3, prevHiddenPost3].firstWhere(
      (post) =>
          post != null &&
          (post == current.program.post1 ||
              post == current.program.hiddenPost1),
      orElse: () => null,
    );

    if (matched != null) {
      return 'Αν ο ${matched.name} κάνει 1ο Νούμερο σήμερα, αυτό σημαίνει ότι θα κάνει 4 ώρες συνεχόμενα γιατί ήταν 3ο Νούμερο χθες.';
    }
    return null;
  }
}

/// The Dorm Guard 3 (Θαλαμοφύλακας 3ο Νούμερο) from yesterday cannot be
/// Post 1 today — their shift does not finish until 09:00 this morning.
class DormGuard3ToPost1Rule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];
    final prevDormGuard3 =
        previous?.otherTasks.reserveDormGuard3 ?? previous?.program.dormGuard3;
    if (prevDormGuard3 == null) return null;

    final post1 = current.otherTasks.reservePost1 ?? current.program.post1;
    final hiddenPost1 =
        current.otherTasks.reserveHiddenPost1 ?? current.program.hiddenPost1;

    if (post1 == prevDormGuard3) {
      return 'Ο ${post1?.name} δεν μπορεί να κάνει 1ο Νούμερο σήμερα γιατί δεν θα έχει τελειώσει το 3ο Νούμερο θαλαμοφύλακας χθες.';
    }
    if (hiddenPost1 == prevDormGuard3) {
      return 'Ο ${hiddenPost1?.name} δεν μπορεί να κάνει 1ο Νούμερο σήμερα γιατί δεν θα έχει τελειώσει το 3ο Νούμερο θαλαμοφύλακας χθες.';
    }
    return null;
  }
}

/// Dorm Guard 3 yesterday cannot be Dorm Guard 1 today (6 hours back-to-back).
class DormGuard3ToDormGuard1Rule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];
    final prevDormGuard3 =
        previous?.otherTasks.reserveDormGuard3 ?? previous?.program.dormGuard3;
    if (prevDormGuard3 == null) return null;

    final dormGuard1 =
        current.otherTasks.reserveDormGuard1 ?? current.program.dormGuard1;
    if (dormGuard1 == prevDormGuard3) {
      return 'Ο ${dormGuard1?.name} κάνει 1ο Νούμερο Θαλαμοφύλακας σήμερα, ενώ ήταν 3ο Νούμερο Θαλαμοφύλακας χθες. Αυτό σημαίνει 6 ώρες συνεχόμενα.';
    }
    return null;
  }
}

/// A cook (ΕΣΤ role) must not be assigned to a guard post.
class CookAssignedToServiceRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final cooks = current.manpower.where((s) => s.role == 'ΕΣΤ').toList();
    final services = [
      current.program.post1,
      current.program.hiddenPost1,
      current.program.post2,
      current.program.hiddenPost2,
      current.program.post3,
      current.program.hiddenPost3,
      current.program.dormGuard1,
      current.program.dormGuard2,
      current.program.dormGuard3,
    ];
    for (final cook in cooks) {
      if (services.contains(cook)) {
        return 'Ο ${cook.name} είναι Εστιάτορας αλλά έχει υπηρεσία.';
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Flag ceremony rules
// ---------------------------------------------------------------------------

/// Warns when a soldier assigned to the flag lowering also has a guard duty
/// that overlaps with the lowering time.
class FlagLoweringConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final timeStr = getFlagLoweringTime(current.date);
    if (timeStr.isEmpty) return null;

    final flagTime = _parseMinutes(timeStr);
    final flagSoldiers = current.otherTasks.flagLowering;
    if (flagSoldiers.isEmpty) return null;

    final duties = [
      _Duty('Σκοπός 1ο Νούμερο', '20:00', '22:00',
          [current.program.post1, current.program.hiddenPost1]),
      _Duty('Σκοπός 2ο Νούμερο', '16:00', '18:00',
          [current.program.post2, current.program.hiddenPost2]),
      _Duty('Σκοπός 3ο Νούμερο', '18:00', '20:00',
          [current.program.post3, current.program.hiddenPost3]),
      _Duty('Θαλαμοφύλακας 1ο Νούμερο', '18:00', '21:00',
          [current.program.dormGuard1]),
      _Duty('Θαλαμοφύλακας 3ο Νούμερο', '15:00', '18:00',
          [current.program.dormGuard3]),
    ];

    for (final duty in duties) {
      if (flagTime >= _parseMinutes(duty.start) &&
          flagTime < _parseMinutes(duty.end)) {
        for (final soldier in flagSoldiers) {
          if (duty.soldiers.contains(soldier)) {
            return 'Ο ${soldier.name} είναι στην σημαία στις ($timeStr) αλλά είναι επίσης ${duty.name}.';
          }
        }
      }
    }
    return null;
  }

  int _parseMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _Duty {
  final String name;
  final String start;
  final String end;
  final List<Soldier?> soldiers;

  _Duty(this.name, this.start, this.end, this.soldiers);
}

/// Dorm Guard 3 from yesterday is still on duty during morning flag rising.
class FlagRisingDormGuard3ConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];
    final prevDormGuard3 =
        previous?.otherTasks.reserveDormGuard3 ?? previous?.program.dormGuard3;

    for (final s in current.otherTasks.flagRising) {
      if (s == prevDormGuard3) {
        return 'Ο ${s.name} είναι στην σημαία το πρωί αλλά είναι ακόμα 3ο Νούμερο Θαλαμοφύλακας από χθες.';
      }
    }
    return null;
  }
}

/// Post 3 (non-ΤΑΧ role) from yesterday is still on duty during morning flag rising.
class FlagRisingPost3ConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];

    final prevPost3 = previous?.program.post3?.role == 'ΤΑΧ'
        ? previous?.otherTasks.reservePost3
        : previous?.program.post3;
    final prevHiddenPost3 = previous?.program.hiddenPost3?.role == 'ΤΑΧ'
        ? previous?.otherTasks.reserveHiddenPost3
        : previous?.program.hiddenPost3;

    for (final s in current.otherTasks.flagRising) {
      if (s == prevPost3 || s == prevHiddenPost3) {
        return 'Ο ${s.name} είναι στην σημάια το πρωί αλλά είναι ακόμα 3ο Νούμερο Σκοπός απο χθες.';
      }
    }
    return null;
  }
}

/// On weekdays, ΤΑΧ soldiers must be at the post office, not the flag ceremony.
class FlagRisingTaxConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.isHoliday || current.isWeekend) return null;
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'TAX') {
        return 'Ο ${s.name} είναι στην σημάια το πρωί αλλά πρέπει να είναι στο Ταχυδρομείο, τις καθημερινές.';
      }
    }
    return null;
  }
}

/// The ΓΕΠ soldier cannot be at the flag lowering on weekdays.
class FlagLoweringGepConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.isHoliday || current.isWeekend) return null;
    final gep = current.program.gep;
    for (final s in current.otherTasks.flagLowering) {
      if (s == gep) {
        return 'Ο ${s.name} είναι στην σημάια στις ${getFlagLoweringTime(current.date)} αλλά έχει υπηρεσία ΓΕΠ.';
      }
    }
    return null;
  }
}

/// An exit-eligible soldier (Εξοδούχος) should not be at flag lowering,
/// unless they are the ΔΠΒ canteen soldier.
class FlagLoweringFreeConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final canLeave = current.canLeaveBase;
    for (final s in current.otherTasks.flagLowering) {
      final freeVersion = canLeave.firstWhereOrNull((e) => e == s);
      if (freeVersion != null && freeVersion.role != 'ΔΠΒ') {
        return 'Ο ${s.name} είναι στην σημάια το απογευμα, αλλά είναι Εξοδούχος.';
      }
    }
    return null;
  }
}

/// The ΔΠΒ canteen soldier must be present at the flag lowering.
class FlagLoweringDpvMissingRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.otherTasks.flagLowering.isEmpty) return null;
    final dpv = current.program.dpvCanteen;
    if (dpv != null && !current.otherTasks.flagLowering.contains(dpv)) {
      return 'Ο ${dpv.name} είναι Κυλικείο ΔΠΒ και πρέπει να είναι στην σημαία το απόγευμα.';
    }
    return null;
  }
}

/// Post 1 soldiers must be present at the morning flag raising.
class FlagRisingPost1RequiredRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.otherTasks.flagRising.isEmpty) return null;
    final post1 = current.otherTasks.reservePost1 ?? current.program.post1;
    if (post1 != null && !current.otherTasks.flagRising.contains(post1)) {
      return 'Το 1ο Νούμερο Σκοπός (${post1.name}) πρέπει να είναι στην έπαρση της σημαίας το πρωί.';
    }
    return null;
  }
}

/// Hidden Post 1 soldiers must be present at the morning flag raising.
class FlagRisingHiddenPost1RequiredRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.otherTasks.flagRising.isEmpty) return null;
    final hiddenPost1 =
        current.otherTasks.reserveHiddenPost1 ?? current.program.hiddenPost1;
    if (hiddenPost1 != null &&
        !current.otherTasks.flagRising.contains(hiddenPost1)) {
      return 'Το 1ο Νούμερο Σκοπός (${hiddenPost1.name}) πρέπει να είναι στην έπαρση της σημαίας το πρωί.';
    }
    return null;
  }
}

/// On weekdays/holidays, the ΓΕΠ soldier from yesterday (or the current ΓΕΠ)
/// should not appear at the morning flag raising.
class FlagRisingGepConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.isHoliday || current.isWeekend) {
      final prevGep = allDailies[_previousDate(current)]?.program.gep;
      for (final s in current.otherTasks.flagRising) {
        if (s == prevGep) {
          return 'Ο ${s.name} είναι στην σημάια το πρωί αλλά είναι ακόμα ΓΕΠ απο χθες. Aλλάζει στις 9:00 σημερα';
        }
      }
    } else {
      for (final s in current.otherTasks.flagRising) {
        if (s.role == 'ΓΕΠ') {
          return 'Ο ${s.name} είναι στην σημάια το πρωί αλλά πρέπει να είναι στο ΓΕΠ, τις καθημερινές.';
        }
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Role-specific flag rules (cook, ΚΨΜ, ΔΠΒ, ΔΜΧ, ΚΥΛΙΚΕΙΟ)
// ---------------------------------------------------------------------------

class FlagRisingCookConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'ΕΣΤ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι Εστιάτορας.';
      }
    }
    return null;
  }
}

class FlagLoweringCookConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagLowering) {
      if (s.role == 'ΕΣΤ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι Εστιάτορας.';
      }
    }
    return null;
  }
}

class FlagRisingKpsmConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'ΚΨΜ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι ΚΨΜτζής.';
      }
    }
    return null;
  }
}

class FlagLoweringKpsmConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagLowering) {
      if (s.role == 'ΚΨΜ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι ΚΨΜτζής.';
      }
    }
    return null;
  }
}

class FlagRisingDpvConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'ΔΠΒ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι Κυλικείο ΔΠΒ.';
      }
    }
    return null;
  }
}

class FlagRisingDmxConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (current.isHoliday || current.isWeekend) return null;
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'ΔΜΧ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι στην ΔΜΧ.';
      }
    }
    return null;
  }
}

class FlagRisingKylikioConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagRising) {
      if (s.role == 'ΚΥΛΙΚΕΙΟ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι Κυλικείο Μεραρχίας.';
      }
    }
    return null;
  }
}

class FlagLoweringKylikioConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    for (final s in current.otherTasks.flagLowering) {
      if (s.role == 'ΚΥΛΙΚΕΙΟ') {
        return 'Ο ${s.name} είναι στην σημάια, αλλά είναι Κυλικείο Μεραρχίας.';
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Cleaning duty rules
// ---------------------------------------------------------------------------

/// Post 3 soldiers and Dorm Guard 3 from yesterday are not yet free and
/// cannot be assigned to cleaning duties.
class Post3CleaningConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final previous = allDailies[_previousDate(current)];

    final post3Soldiers = [
      previous?.program.post3?.role == 'ΤΑΧ'
          ? previous?.otherTasks.reservePost3
          : previous?.program.post3,
      previous?.program.hiddenPost3?.role == 'ΤΑΧ'
          ? previous?.otherTasks.reserveHiddenPost3
          : previous?.program.hiddenPost3,
    ];
    final dormGuard3 =
        previous?.otherTasks.reserveDormGuard3 ?? previous?.program.dormGuard3;

    final barracks = current.otherTasks.cleanBarracksArea;
    final toilets = current.otherTasks.cleanToiletsArea;

    for (final s in post3Soldiers) {
      if (s != null && (barracks.contains(s) || toilets.contains(s))) {
        return 'Ο ${s.name} είναι 3ο Νούμερο Σκοπός. Δεν μπορεί να κάνει καθαριότητες.';
      }
    }
    if (dormGuard3 != null &&
        (barracks.contains(dormGuard3) || toilets.contains(dormGuard3))) {
      return 'Ο ${dormGuard3.name} είναι 3ο Νούμερο Θαλαμοφύλακας. Δεν μπορεί να κάνει καθαριότητες.';
    }
    return null;
  }
}

/// On weekends, Post 1 soldiers cannot be assigned to cleaning duties.
class Post1CleaningWeekendRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (!current.isWeekend && !current.isHoliday) return null;

    final post1 = current.otherTasks.reservePost1 ?? current.program.post1;
    final hiddenPost1 =
        current.otherTasks.reserveHiddenPost1 ?? current.program.hiddenPost1;

    final cleaners = <Soldier>{
      if (current.otherTasks.cleanBinArea != null)
        current.otherTasks.cleanBinArea!,
      if (current.otherTasks.cleanDormGuardArea != null)
        current.otherTasks.cleanDormGuardArea!,
      ...current.otherTasks.cleanSupervisorArea,
      ...current.otherTasks.cleanToiletsArea,
      ...current.otherTasks.cleanBarracksArea,
    };

    if (post1 != null && cleaners.contains(post1)) {
      return 'Ο ${post1.name} είναι 1ο Νούμερο Σκοπός και δεν μπορεί να κάνει καθαριότητες τα ΣΚ/Αργίες.';
    }
    if (hiddenPost1 != null && cleaners.contains(hiddenPost1)) {
      return 'Ο ${hiddenPost1.name} είναι 1ο Νούμερο Σκοπός και δεν μπορεί να κάνει καθαριότητες τα ΣΚ/Αργίες.';
    }
    return null;
  }
}

/// On weekends, Post 1 and Dorm Guard 3 (from yesterday) cannot be assigned
/// to barracks cleaning.
class BarracksCleaningWeekendRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (!current.isWeekend && !current.isHoliday) return null;

    final previous = allDailies[_previousDate(current)];
    final post1 = current.otherTasks.reservePost1 ?? current.program.post1;
    final hiddenPost1 =
        current.otherTasks.reserveHiddenPost1 ?? current.program.hiddenPost1;
    final dormGuard3 =
        previous?.otherTasks.reserveDormGuard3 ?? previous?.program.dormGuard3;

    for (final s in current.otherTasks.cleanBarracksArea) {
      if (s == post1 || s == hiddenPost1) {
        return 'Ο ${s.name} είναι στην καθαριότητα αλλά είναι 1ο Νούμερο Σκοπός.';
      }
      if (s == dormGuard3) {
        return 'Ο ${s.name} είναι στην καθαριότητα αλλά είναι 3ο Νούμερο Θαλαμοφύλακας, απο χθές.';
      }
    }
    return null;
  }
}

/// Soldiers who cleaned the Εποπτείο yesterday cannot be assigned to
/// barracks, toilets, bin, or dorm-guard-area cleaning today.
class SupervisorCleaningCarryoverRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final prevCleaners =
        allDailies[_previousDate(current)]?.otherTasks.cleanSupervisorArea;
    if (prevCleaners == null || prevCleaners.isEmpty) return null;

    for (final soldier in prevCleaners) {
      if (current.otherTasks.cleanBarracksArea.contains(soldier)) {
        return 'Ο ${soldier.name} έχει καθαριλοτητς Εποπτείου απο χθές. Δεν μπορεί να είναι στην καθαριότητα θαλάμων.';
      }
      if (current.otherTasks.cleanToiletsArea.contains(soldier)) {
        return 'Ο ${soldier.name} έχει καθαριλοτητς Εποπτείου απο χθές. Δεν μπορεί να είναι στην καθαριότητα τουαλετών.';
      }
      if (soldier == current.otherTasks.cleanBinArea) {
        return 'Ο ${soldier.name} έχει καθαριλοτητς Εποπτείου απο χθές. Δεν μπορεί να είναι στην καθαριότητα κάδων.';
      }
      if (soldier == current.otherTasks.cleanDormGuardArea) {
        return 'Ο ${soldier.name} έχει καθαριλοτητς Εποπτείου απο χθές. Δεν μπορεί να είναι στην καθαριότητα χ. θαλαμοφύλακα σήμερα.';
      }
    }
    return null;
  }
}

/// The ΓΕΠ soldier from yesterday cannot be in barracks or toilet cleaning
/// on a weekend/holiday (they carry over until 09:00).
class GepCleaningWeekendRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (!current.isWeekend && !current.isHoliday) return null;
    final prevGep = allDailies[_previousDate(current)]?.program.gep;

    for (final s in current.otherTasks.cleanBarracksArea) {
      if (s == prevGep) {
        return 'Ο ${s.name} είναι στην καθαριότητα αλλά είναι ΓΕΠ απο χθες.';
      }
    }
    for (final s in current.otherTasks.cleanToiletsArea) {
      if (s == prevGep) {
        return 'Ο ${s.name} είναι στην καθαριότητα αλλά είναι ΓΕΠ απο χθες.';
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Division canteen (Κυλικείο Μεραρχίας) rules
// ---------------------------------------------------------------------------

/// Division canteen soldiers must be Dorm Guard 1 or 2 on weekends, and
/// Εξοδούχοι on weekdays.
class DivisionCanteenAssignmentRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    final cleaners = current.otherTasks.cleanDivisionArea;
    if (cleaners.isEmpty) return null;

    if (current.isWeekend || current.isHoliday) {
      final dg1 = current.program.dormGuard1;
      final dg2 = current.program.dormGuard2;
      for (final s in cleaners) {
        if (s != dg1 && s != dg2) {
          return 'Ο ${s.name} είναι στην καθαριότητα Μεραρχίας, αλλά πρέπει να είναι 1ο ή 2ο Νούμερο Θαλαμοφύλακας, επιδη είναι ΣΚ ή Αργία.';
        }
      }
    } else {
      for (final s in cleaners) {
        if (!current.canLeaveBase.contains(s)) {
          return 'Ο ${s.name} είναι στην καθαριότητα Μεραρχίας, αλλά δεν είναι Εξοδούχος.';
        }
      }
    }
    return null;
  }
}

/// On weekends, division canteen soldiers who are also Εξοδούχοι may leave
/// before the cleaning time.
class DivisionCanteenExitConflictRule implements WarningRule {
  @override
  String? check(Daily current, Map<Date, Daily> allDailies) {
    if (!current.isHoliday && !current.isWeekend) return null;
    for (final s in current.otherTasks.cleanDivisionArea) {
      if (current.canLeaveBase.contains(s)) {
        return 'Ο ${s.name} είναι στην καθαριότητα Μεραρχίας αλλά είναι Εξοδούχος και μπορεί να βγει πριν την καθαριότητα.';
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// WarningsCubit
// ---------------------------------------------------------------------------

class WarningsCubit extends Cubit<WarningsState> {
  WarningsCubit() : super(const WarningsState());

  final List<WarningRule> _rules = [
    DivisionCanteenAssignmentRule(),
    SupervisorCleaningCarryoverRule(),
    DormGuard3ToDormGuard1Rule(),
    Post3ToPost1Rule(),
    DormGuard3ToPost1Rule(),
    FlagLoweringConflictRule(),
    FlagRisingDormGuard3ConflictRule(),
    FlagRisingPost3ConflictRule(),
    FlagRisingTaxConflictRule(),
    FlagLoweringGepConflictRule(),
    FlagLoweringFreeConflictRule(),
    FlagLoweringCookConflictRule(),
    FlagRisingCookConflictRule(),
    FlagRisingKpsmConflictRule(),
    FlagLoweringKpsmConflictRule(),
    FlagRisingDpvConflictRule(),
    FlagRisingDmxConflictRule(),
    FlagLoweringDpvMissingRule(),
    FlagRisingKylikioConflictRule(),
    FlagLoweringKylikioConflictRule(),
    FlagRisingGepConflictRule(),
    CookAssignedToServiceRule(),
    Post3CleaningConflictRule(),
    BarracksCleaningWeekendRule(),
    DivisionCanteenExitConflictRule(),
    GepCleaningWeekendRule(),
    FlagRisingPost1RequiredRule(),
    FlagRisingHiddenPost1RequiredRule(),
    Post1CleaningWeekendRule(),
  ];

  void calculateWarnings(Daily current, Map<Date, Daily> allDailies) {
    final warnings = _rules
        .map((rule) => rule.check(current, allDailies))
        .whereType<String>()
        .toList();
    emit(WarningsState(errors: state.errors, warnings: warnings));
  }

  void addWarningMsg(String warning) {
    debugPrint('Warning: $warning');
    emit(WarningsState(
      errors: state.errors,
      warnings: [...state.warnings, warning],
    ));
  }
}

// ---------------------------------------------------------------------------
// Shared utility
// ---------------------------------------------------------------------------

Date _previousDate(Daily current) => Date.fromDateTime(
    current.date.toDateTime().subtract(const Duration(days: 1)));

/// Returns the scheduled flag-lowering time string for [date].
String getFlagLoweringTime(Date date) {
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

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
