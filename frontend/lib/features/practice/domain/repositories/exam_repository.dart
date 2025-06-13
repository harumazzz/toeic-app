import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam.dart';

abstract interface class ExamRepository {
  Future<Either<Failure, Exam>> getExamById({
    required final int examId,
  });

  Future<Either<Failure, List<Exam>>> getExams({
    required final int limit,
    required final int offset,
  });
}
