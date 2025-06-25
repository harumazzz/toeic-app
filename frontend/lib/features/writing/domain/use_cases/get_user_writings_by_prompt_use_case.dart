import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/user_writing_repository_impl.dart';
import '../entities/user_writing.dart';
import '../repositories/user_writing_repository.dart';

part 'get_user_writings_by_prompt_use_case.g.dart';

@riverpod
GetUserWritingsByPromptUseCase getUserWritingsByPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(userWritingRepositoryProvider);
  return GetUserWritingsByPromptUseCase(repository);
}

class GetUserWritingsByPromptUseCase
    implements UseCase<List<UserWriting>, int> {
  const GetUserWritingsByPromptUseCase(this._repository);

  final UserWritingRepository _repository;

  @override
  Future<Either<Failure, List<UserWriting>>> call(
    final int promptId,
  ) async => _repository.listUserWritingsByPromptId(promptId: promptId);
}
