import 'package:dartz/dartz.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/stored_data.dart';
import 'package:ls_ypiresies/features/assignments/data/datasource/assignments_datasource.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';

class AssignmentsRepositoryImplementation implements AssignmentsRepository {
  final AssignmentsDataSource assignmentsDataSource;

  AssignmentsRepositoryImplementation(
    this.assignmentsDataSource,
  );

  @override
  Future<Either<Exception, StoredData>> getStoredData() async {
    try {
      final storedData = await assignmentsDataSource.getStoredData();
      return Right(storedData);
    } on Exception catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> saveDaily(Daily daily) async {
    try {
      await assignmentsDataSource.saveDaily(daily);
      return const Right(null);
    } on Exception catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> signDate(Date date) async {
    try {
      await assignmentsDataSource.signDate(date);
      return const Right(null);
    } on Exception catch (e) {
      return Left(e);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
