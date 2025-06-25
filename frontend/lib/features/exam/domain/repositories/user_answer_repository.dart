import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam.dart';
import '../entities/result.dart';

abstract interface class UserAnswerRepository {
  Future<Either<Failure, UserAnswerResponse>> getUserAnswers();

  Future<Either<Failure, UserAnswer>> createUserAnswer(
    final UserAnswerRequest userAnswer,
  );

  Future<Either<Failure, UserAnswer>> getUserAnswerById(
    final int id,
  );

  Future<Either<Failure, UserAnswer>> updateUserAnswer(
    final int id,
    final UpdateUserAnswerRequest userAnswer,
  );

  Future<Either<Failure, void>> deleteUserAnswer(
    final int id,
  );

  Future<Either<Failure, UserAnswer>> abandonUserAnswer(
    final int id,
  );

  Future<Either<Failure, UserAnswer>> completeUserAnswer(
    final int id,
  );
}
