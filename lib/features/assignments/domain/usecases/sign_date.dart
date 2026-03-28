import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/usecases/usecase.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';

class SignDate implements UseCase<void, SignDateParams> {
  final AssignmentsRepository assignmentsRepository;

  SignDate(this.assignmentsRepository);

  @override
  Future<Either<Exception, void>> call(SignDateParams params) async {
    return await assignmentsRepository.signDate(params.date);
  }
}

class SignDateParams extends Equatable {
  final Date date;

  const SignDateParams(this.date);

  @override
  List<Object?> get props => [date];
}
