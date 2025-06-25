import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam.dart';

abstract interface class ExamRepository {
  Future<Either<Failure, Exam>> getExamQuestions(
    final int examId,
  );
}
