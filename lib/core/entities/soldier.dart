import 'package:equatable/equatable.dart';

class Soldier extends Equatable {
  final String name;
  final String? role;
  final String? id;
  final String? phoneNumber;
  final String? unit;
  final String? ability;
  final String? note;
  final String? rank;
  final String? esso;
  final String? dateofArival;

  const Soldier({
    required this.name,
    this.role,
    this.id,
    this.phoneNumber,
    this.unit,
    this.ability,
    this.note,
    this.rank,
    this.esso,
    this.dateofArival,
  });

  @override
  List<Object?> get props => [name];
}
