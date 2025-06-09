import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/question.dart';

abstract class QuestionRepository {
  Future<Either<Failure, List<Question>>> getQuestionsByContentId({
    required final int contentId,
  });

  Future<Either<Failure, Question>> getQuestionById({
    required final int questionId,
  });
}
