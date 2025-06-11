import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/progress.dart';

abstract class ProgressRepository {
  Future<Either<Failure, WordProgress>> addNewProgress({
    required final WordProgressRequest request,
  });

  Future<Either<Failure, List<WordProgress>>> getReviewsProgress({
    required final int limit,
  });

  Future<Either<Failure, WordProgress>> getWordProgressById({
    required final int wordId,
  });

  Future<Either<Failure, Progress?>> getProgressById({
    required final int wordId,
  });

  Future<Either<Failure, WordProgress>> updateProgress({
    required final int wordId,
    required final WordProgressRequest request,
  });

  Future<Either<Failure, Success>> deleteProgress({
    required final int wordId,
  });
}
