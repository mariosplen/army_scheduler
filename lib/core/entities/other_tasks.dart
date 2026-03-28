import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';

part 'other_tasks.g.dart';

/// Holds assignments that are not part of the main daily program sheet —
/// reserve soldiers (κωλυόμενοι), cleaning duties, flag details, food
/// transfers, and executive officer references loaded from auxiliary sheets.
@CopyWith()
class OtherTasks extends Equatable {
  // Reserve (κωλυόμενοι) assignments
  final Soldier? reservePost1;
  final Soldier? reserveHiddenPost1;
  final Soldier? reservePost2;
  final Soldier? reserveHiddenPost2;
  final Soldier? reservePost3;
  final Soldier? reserveHiddenPost3;
  final Soldier? reserveDormGuard1;
  final Soldier? reserveDormGuard2;
  final Soldier? reserveDormGuard3;

  // Flag ceremony details
  final List<Soldier> flagRising;
  final List<Soldier> flagLowering;

  // Cleaning duties
  final Soldier? cleanBinArea;
  final Soldier? cleanDormGuardArea;
  final List<Soldier> cleanSupervisorArea;
  final List<Soldier> cleanDivisionArea;
  final List<Soldier> cleanToiletsArea;
  final List<Soldier> cleanBarracksArea;

  // Food logistics
  final Soldier? passengerForFoodLunch;
  final Soldier? passengerForFoodDinner;
  final List<Soldier> foodTransferLunch;
  final List<Soldier> foodTransferDinner;

  // ΚΨΜ duty
  final Soldier? kpsm;

  // Executive officers loaded from auxiliary Excel sheets
  final Soldier? execGep;
  final Soldier? execDutyOfficer;
  final Soldier? execDutyOfficerMP;
  final Soldier? execDutySupervisor;
  final Soldier? execCCTV1;
  final Soldier? execCCTV2;
  final Soldier? execCCTV3;
  final Soldier? execGateGuard;
  final Soldier? execCook;

  const OtherTasks({
    this.reservePost1,
    this.reserveHiddenPost1,
    this.reservePost2,
    this.reserveHiddenPost2,
    this.reservePost3,
    this.reserveHiddenPost3,
    this.reserveDormGuard1,
    this.reserveDormGuard2,
    this.reserveDormGuard3,
    this.flagRising = const [],
    this.flagLowering = const [],
    this.cleanBinArea,
    this.cleanDormGuardArea,
    this.cleanSupervisorArea = const [],
    this.cleanDivisionArea = const [],
    this.cleanToiletsArea = const [],
    this.cleanBarracksArea = const [],
    this.passengerForFoodLunch,
    this.passengerForFoodDinner,
    this.foodTransferLunch = const [],
    this.foodTransferDinner = const [],
    this.kpsm,
    this.execGep,
    this.execDutyOfficer,
    this.execDutyOfficerMP,
    this.execDutySupervisor,
    this.execCCTV1,
    this.execCCTV2,
    this.execCCTV3,
    this.execGateGuard,
    this.execCook,
  });

  factory OtherTasks.fromJson(Map<String, dynamic> json) {
    Soldier? toSoldier(String? name) {
      if (name == null || name.isEmpty) return null;
      return Soldier(name: name);
    }

    List<Soldier> toSoldierList(List<dynamic>? list) {
      if (list == null) return [];
      return list.map((e) => Soldier(name: e.toString())).toList();
    }

    return OtherTasks(
      reservePost1: toSoldier(json['reservePost1']),
      reserveHiddenPost1: toSoldier(json['reserveHiddenPost1']),
      reservePost2: toSoldier(json['reservePost2']),
      reserveHiddenPost2: toSoldier(json['reserveHiddenPost2']),
      reservePost3: toSoldier(json['reservePost3']),
      reserveHiddenPost3: toSoldier(json['reserveHiddenPost3']),
      reserveDormGuard1: toSoldier(json['reserveDormGuard1']),
      reserveDormGuard2: toSoldier(json['reserveDormGuard2']),
      reserveDormGuard3: toSoldier(json['reserveDormGuard3']),
      flagRising: toSoldierList(json['flagRising']),
      flagLowering: toSoldierList(json['flagLowering']),
      cleanBinArea: toSoldier(json['cleanBinArea']),
      cleanDormGuardArea: toSoldier(json['cleanDormGuardArea']),
      cleanSupervisorArea: toSoldierList(json['cleanSupervisorArea']),
      cleanDivisionArea: toSoldierList(json['cleanDivisionArea']),
      cleanToiletsArea: toSoldierList(json['cleanToiletsArea']),
      cleanBarracksArea: toSoldierList(json['cleanBarracksArea']),
      passengerForFoodLunch: toSoldier(json['passengerForFoodLunch']),
      passengerForFoodDinner: toSoldier(json['passengerForFoodDinner']),
      foodTransferLunch: toSoldierList(json['foodTransferLunch']),
      foodTransferDinner: toSoldierList(json['foodTransferDinner']),
      kpsm: toSoldier(json['kpsm']),
      execGep: toSoldier(json['execGep']),
      execDutyOfficer: toSoldier(json['execDutyOfficer']),
      execDutyOfficerMP: toSoldier(json['execDutyOfficerMP']),
      execDutySupervisor: toSoldier(json['execDutySupervisor']),
      execCCTV1: toSoldier(json['execCCTV1']),
      execCCTV2: toSoldier(json['execCCTV2']),
      execCCTV3: toSoldier(json['execCCTV3']),
      execGateGuard: toSoldier(json['execGateGuard']),
      execCook: toSoldier(json['execCook']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    void addSoldier(String key, Soldier? s) {
      if (s != null) data[key] = s.name;
    }

    void addSoldierList(String key, List<Soldier> list) {
      if (list.isNotEmpty) data[key] = list.map((s) => s.name).toList();
    }

    addSoldier('reservePost1', reservePost1);
    addSoldier('reserveHiddenPost1', reserveHiddenPost1);
    addSoldier('reservePost2', reservePost2);
    addSoldier('reserveHiddenPost2', reserveHiddenPost2);
    addSoldier('reservePost3', reservePost3);
    addSoldier('reserveHiddenPost3', reserveHiddenPost3);
    addSoldier('reserveDormGuard1', reserveDormGuard1);
    addSoldier('reserveDormGuard2', reserveDormGuard2);
    addSoldier('reserveDormGuard3', reserveDormGuard3);

    addSoldierList('flagRising', flagRising);
    addSoldierList('flagLowering', flagLowering);

    addSoldier('cleanBinArea', cleanBinArea);
    addSoldier('cleanDormGuardArea', cleanDormGuardArea);
    addSoldierList('cleanSupervisorArea', cleanSupervisorArea);
    addSoldierList('cleanDivisionArea', cleanDivisionArea);
    addSoldierList('cleanToiletsArea', cleanToiletsArea);
    addSoldierList('cleanBarracksArea', cleanBarracksArea);

    addSoldier('passengerForFoodLunch', passengerForFoodLunch);
    addSoldier('passengerForFoodDinner', passengerForFoodDinner);
    addSoldierList('foodTransferLunch', foodTransferLunch);
    addSoldierList('foodTransferDinner', foodTransferDinner);

    addSoldier('kpsm', kpsm);
    addSoldier('execGep', execGep);
    addSoldier('execDutyOfficer', execDutyOfficer);
    addSoldier('execDutyOfficerMP', execDutyOfficerMP);
    addSoldier('execDutySupervisor', execDutySupervisor);
    addSoldier('execCCTV1', execCCTV1);
    addSoldier('execCCTV2', execCCTV2);
    addSoldier('execCCTV3', execCCTV3);
    addSoldier('execGateGuard', execGateGuard);
    addSoldier('execCook', execCook);

    return data;
  }

  @override
  List<Object?> get props => [
        reservePost1,
        reserveHiddenPost1,
        reservePost2,
        reserveHiddenPost2,
        reservePost3,
        reserveHiddenPost3,
        reserveDormGuard1,
        reserveDormGuard2,
        reserveDormGuard3,
        flagRising,
        flagLowering,
        cleanBinArea,
        cleanDormGuardArea,
        cleanSupervisorArea,
        cleanDivisionArea,
        cleanToiletsArea,
        cleanBarracksArea,
        passengerForFoodLunch,
        passengerForFoodDinner,
        foodTransferLunch,
        foodTransferDinner,
        kpsm,
        execGep,
        execDutyOfficer,
        execDutyOfficerMP,
        execDutySupervisor,
        execCCTV1,
        execCCTV2,
        execCCTV3,
        execGateGuard,
        execCook,
      ];
}
