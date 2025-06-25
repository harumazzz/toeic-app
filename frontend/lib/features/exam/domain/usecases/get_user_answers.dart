import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_answer_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/user_answer_repository.dart';

part 'get_user_answers.g.dart';

@riverpod
GetUserAnswers getUserAnswers(
  final Ref ref,
) {
  final repository = ref.watch(userAnswerRepositoryProvider);
  return GetUserAnswers(repository);
}

class GetUserAnswers implements UseCase<UserAnswerResponse, NoParams> {
  const GetUserAnswers(this._repository);

  final UserAnswerRepository _repository;

  @override
  Future<Either<Failure, UserAnswerResponse>> call(
    final NoParams params,
  ) async => _repository.getUserAnswers();
}
