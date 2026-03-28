import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';

part 'program.g.dart';

@CopyWith()
class Program extends Equatable {
  final Soldier? post1;
  final Soldier? hiddenPost1;
  final Soldier? post2;
  final Soldier? hiddenPost2;
  final Soldier? post3;
  final Soldier? hiddenPost3;
  final Soldier? dormGuard1;
  final Soldier? dormGuard2;
  final Soldier? dormGuard3;
  final Soldier? dutySergeant;
  final Soldier? kitchen;
  final Soldier? gep;
  final Soldier? dpvCanteen;
  final List<Soldier> divisionCanteen;
  final List<Soldier> detached;
  final List<Soldier> onLeave;
  final List<Soldier> exempt;
  final List<Soldier> exits;

  const Program({
    this.post1,
    this.hiddenPost1,
    this.post2,
    this.hiddenPost2,
    this.post3,
    this.hiddenPost3,
    this.dormGuard1,
    this.dormGuard2,
    this.dormGuard3,
    this.dutySergeant,
    this.kitchen,
    this.gep,
    this.dpvCanteen,
    this.divisionCanteen = const [],
    this.detached = const [],
    this.onLeave = const [],
    this.exempt = const [],
    this.exits = const [],
  });

  @override
  List<Object?> get props => [
        post1,
        hiddenPost1,
        post2,
        hiddenPost2,
        post3,
        hiddenPost3,
        dormGuard1,
        dormGuard2,
        dormGuard3,
        dutySergeant,
        divisionCanteen,
        kitchen,
        gep,
        dpvCanteen,
        detached,
        onLeave,
        exempt,
        exits,
      ];
}
