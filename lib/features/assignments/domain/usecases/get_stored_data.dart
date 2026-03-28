import 'package:dartz/dartz.dart';
import 'package:ls_ypiresies/core/entities/stored_data.dart';
import 'package:ls_ypiresies/core/usecases/usecase.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';

class GetStoredData implements UseCase<StoredData, NoParams> {
  final AssignmentsRepository assignmentsRepository;

  GetStoredData(this.assignmentsRepository);

  @override
  Future<Either<Exception, StoredData>> call(NoParams params) async {
    return await assignmentsRepository.getStoredData();
  }
}
