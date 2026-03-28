import 'package:dartz/dartz.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/stored_data.dart';

abstract class AssignmentsRepository {
  Future<Either<Exception, StoredData>> getStoredData();

  Future<Either<Exception, void>> saveDaily(Daily daily);

  Future<Either<Exception, void>> signDate(Date date);
}
