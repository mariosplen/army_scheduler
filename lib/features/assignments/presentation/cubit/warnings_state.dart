part of 'warnings_cubit.dart';

class WarningsState extends Equatable {
  const WarningsState({
    this.errors = const [],
    this.warnings = const [],
  });

  final List<String> errors;
  final List<String> warnings;

  @override
  List<Object> get props => [errors, warnings];
}
