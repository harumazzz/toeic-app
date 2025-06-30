import 'package:dart_either/dart_either.dart';

import '../../../../core/error/failures.dart';
import '../entities/result.dart';

abstract interface class AnswerSubmitRepository {
  Future<Either<Failure, SubmittedAnswer>> submitAnswers({
    required final SubmitAnswersRequest request,
  });
}
