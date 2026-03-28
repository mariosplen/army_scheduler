import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/usecases/usecase.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';

class SaveDaily implements UseCase<void, SaveDailyParams> {
  final AssignmentsRepository assignmentsRepository;

  SaveDaily(this.assignmentsRepository);

  @override
  Future<Either<Exception, void>> call(SaveDailyParams params) async {
    return await assignmentsRepository.saveDaily(params.daily);
  }
}

class SaveDailyParams extends Equatable {
  final Daily daily;

  const SaveDailyParams(this.daily);

  @override
  List<Object?> get props => [daily];
}
