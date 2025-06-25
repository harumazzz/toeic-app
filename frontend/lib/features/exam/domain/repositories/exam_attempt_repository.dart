import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam.dart';

abstract interface class ExamAttemptRepository {
  Future<Either<Failure, List<ExamAttempt>>> getExamAttempts();

  Future<Either<Failure, ExamAttempt>> createExamAttempt(
    final ExamRequest examAttempt,
  );

  Future<Either<Failure, ExamStats>> getExamAttemptStats();

  Future<Either<Failure, ExamAttempt>> getExamAttemptById(
    final int id,
  );

  Future<Either<Failure, ExamAttempt>> updateExamAttempt(
    final int id,
    final UpdateExamAttempt examAttempt,
  );

  Future<Either<Failure, void>> deleteExamAttempt(
    final int id,
  );

  Future<Either<Failure, ExamAttempt>> abandonExamAttempt(
    final int id,
  );

  Future<Either<Failure, ExamAttempt>> completeExamAttempt(
    final int id,
  );

  Future<Either<Failure, Map<String, dynamic>>> getExamLeaderboard(
    final int examId,
  );
}
