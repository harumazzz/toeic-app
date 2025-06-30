import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/answer_submit_repository_impl.dart';
import '../entities/result.dart';
import '../repositories/answer_submit_repository.dart';

part 'submit_answer.g.dart';

@riverpod
SubmitAnswerUseCase submitAnswer(
  final Ref ref,
) {
  final repository = ref.watch(answerSubmitRepositoryProvider);
  return SubmitAnswerUseCase(repository: repository);
}

class SubmitAnswerUseCase
    implements UseCase<SubmittedAnswer, SubmitAnswersRequest> {
  const SubmitAnswerUseCase({
    required this.repository,
  });

  final AnswerSubmitRepository repository;

  @override
  Future<Either<Failure, SubmittedAnswer>> call(
    final SubmitAnswersRequest params,
  ) => repository.submitAnswers(
    request: params,
  );
}
