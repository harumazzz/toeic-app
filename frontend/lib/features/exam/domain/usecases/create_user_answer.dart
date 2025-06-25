import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_answer_repository_impl.dart';
import '../entities/exam.dart';
import '../entities/result.dart';
import '../repositories/user_answer_repository.dart';

part 'create_user_answer.freezed.dart';
part 'create_user_answer.g.dart';

@riverpod
CreateUserAnswer createUserAnswer(
  final Ref ref,
) {
  final repository = ref.watch(userAnswerRepositoryProvider);
  return CreateUserAnswer(repository);
}

class CreateUserAnswer implements UseCase<UserAnswer, CreateUserAnswerParams> {
  const CreateUserAnswer(this._repository);

  final UserAnswerRepository _repository;

  @override
  Future<Either<Failure, UserAnswer>> call(
    final CreateUserAnswerParams params,
  ) async => _repository.createUserAnswer(
    params.userAnswer,
  );
}

@freezed
sealed class CreateUserAnswerParams with _$CreateUserAnswerParams {
  const factory CreateUserAnswerParams({
    required final UserAnswerRequest userAnswer,
  }) = _CreateUserAnswerParams;
}
