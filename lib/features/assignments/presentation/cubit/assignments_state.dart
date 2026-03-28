part of 'assignments_cubit.dart';

class AssignmentsState extends Equatable {
  final Daily daily;
  final bool isLoading;
  final Date? minDate;
  final Date? maxDate;

  const AssignmentsState({
    required this.daily,
    this.isLoading = false,
    this.minDate,
    this.maxDate,
  });

  AssignmentsState copyWith({
    Daily? daily,
    bool? isLoading,
    Date? minDate,
    Date? maxDate,
  }) {
    return AssignmentsState(
      daily: daily ?? this.daily,
      isLoading: isLoading ?? this.isLoading,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
    );
  }

  @override
  List<Object?> get props => [
        daily,
        isLoading,
        minDate,
        maxDate,
      ];
}
