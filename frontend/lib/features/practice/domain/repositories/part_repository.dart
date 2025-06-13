import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/part.dart';

abstract interface class PartRepository {
  Future<Either<Failure, Part>> getPartById({
    required final int partId,
  });

  Future<Either<Failure, List<Part>>> getPartsByExamId({
    required final int examId,
  });
}
