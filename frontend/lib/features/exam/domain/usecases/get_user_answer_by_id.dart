import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_answer_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/user_answer_repository.dart';

part 'get_user_answer_by_id.freezed.dart';
part 'get_user_answer_by_id.g.dart';

@riverpod
GetUserAnswerById getUserAnswerById(
  final Ref ref,
) {
  final repository = ref.watch(userAnswerRepositoryProvider);
  return GetUserAnswerById(repository);
}

class GetUserAnswerById
    implements UseCase<UserAnswer, GetUserAnswerByIdParams> {
  const GetUserAnswerById(this._repository);

  final UserAnswerRepository _repository;

  @override
  Future<Either<Failure, UserAnswer>> call(
    final GetUserAnswerByIdParams params,
  ) async => _repository.getUserAnswerById(params.id);
}

@freezed
sealed class GetUserAnswerByIdParams with _$GetUserAnswerByIdParams {
  const factory GetUserAnswerByIdParams({
    required final int id,
  }) = _GetUserAnswerByIdParams;
}
