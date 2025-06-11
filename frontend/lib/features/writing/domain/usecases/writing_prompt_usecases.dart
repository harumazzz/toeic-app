import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/writing_repository_impl.dart';
import '../entities/writing_prompt.dart';
import '../repositories/writing_repository.dart';

part 'writing_prompt_usecases.g.dart';
part 'writing_prompt_usecases.freezed.dart';

@riverpod
CreateWritingPromptUseCase createWritingPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return CreateWritingPromptUseCase(repository);
}

class CreateWritingPromptUseCase
    implements UseCase<WritingPrompt, WritingPromptRequest> {
  const CreateWritingPromptUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, WritingPrompt>> call(
    final WritingPromptRequest request,
  ) async => _repository.createWritingPrompt(request: request);
}

@riverpod
GetWritingPromptUseCase getWritingPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return GetWritingPromptUseCase(repository);
}

class GetWritingPromptUseCase implements UseCase<WritingPrompt, int> {
  const GetWritingPromptUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, WritingPrompt>> call(
    final int id,
  ) async => _repository.getWritingPrompt(id: id);
}

@riverpod
ListWritingPromptsUseCase listWritingPromptsUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return ListWritingPromptsUseCase(repository);
}

class ListWritingPromptsUseCase
    implements UseCase<List<WritingPrompt>, NoParams> {
  const ListWritingPromptsUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, List<WritingPrompt>>> call(
    final NoParams params,
  ) async => _repository.listWritingPrompts();
}

@freezed
sealed class UpdateWritingPromptRequest with _$UpdateWritingPromptRequest {
  const factory UpdateWritingPromptRequest({
    required final int id,
    required final WritingPromptRequest request,
  }) = _UpdateWritingPromptRequest;
}

@riverpod
UpdateWritingPromptUseCase updateWritingPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return UpdateWritingPromptUseCase(repository);
}

class UpdateWritingPromptUseCase
    implements UseCase<WritingPrompt, UpdateWritingPromptRequest> {
  const UpdateWritingPromptUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, WritingPrompt>> call(
    final UpdateWritingPromptRequest request,
  ) async => _repository.updateWritingPrompt(
    id: request.id,
    request: request.request,
  );
}

@riverpod
DeleteWritingPromptUseCase deleteWritingPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return DeleteWritingPromptUseCase(repository);
}

class DeleteWritingPromptUseCase implements UseCase<Success, int> {
  const DeleteWritingPromptUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, Success>> call(
    final int id,
  ) async => _repository.deleteWritingPrompt(
    id: id,
  );
}

@riverpod
GetWritingPromptsByTopicUseCase getWritingPromptsByTopicUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return GetWritingPromptsByTopicUseCase(repository);
}

class GetWritingPromptsByTopicUseCase
    implements UseCase<List<WritingPrompt>, String> {
  const GetWritingPromptsByTopicUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, List<WritingPrompt>>> call(
    final String topic,
  ) async {
    final result = await _repository.listWritingPrompts();

    return result.fold(
      ifLeft: Left.new,
      ifRight: (final prompts) {
        final filteredPrompts = [
          ...prompts.where(
            (final prompt) =>
                prompt.topic?.toLowerCase() == topic.toLowerCase(),
          ),
        ];
        return Right(filteredPrompts);
      },
    );
  }
}

@riverpod
GetWritingPromptsByDifficultyUseCase getWritingPromptsByDifficultyUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return GetWritingPromptsByDifficultyUseCase(repository);
}

class GetWritingPromptsByDifficultyUseCase
    implements UseCase<List<WritingPrompt>, String> {
  GetWritingPromptsByDifficultyUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, List<WritingPrompt>>> call(
    final String difficultyLevel,
  ) async {
    final result = await _repository.listWritingPrompts();

    return result.fold(
      ifLeft: Left.new,
      ifRight: (final prompts) {
        final filteredPrompts = [
          ...prompts.where(
            (final prompt) =>
                prompt.difficultyLevel?.toLowerCase() ==
                difficultyLevel.toLowerCase(),
          ),
        ];
        return Right(filteredPrompts);
      },
    );
  }
}

@riverpod
GetRandomWritingPromptUseCase getRandomWritingPromptUseCase(
  final Ref ref,
) {
  final repository = ref.watch(writingRepositoryProvider);
  return GetRandomWritingPromptUseCase(repository);
}

@freezed
sealed class RandomWritingPromptParams with _$RandomWritingPromptParams {
  const factory RandomWritingPromptParams({
    final String? difficultyLevel,
    final String? topic,
  }) = _RandomWritingPromptParams;
}

class GetRandomWritingPromptUseCase
    implements UseCase<WritingPrompt, RandomWritingPromptParams> {
  GetRandomWritingPromptUseCase(this._repository);
  final WritingRepository _repository;

  @override
  Future<Either<Failure, WritingPrompt>> call(
    final RandomWritingPromptParams params,
  ) async {
    final result = await _repository.listWritingPrompts();

    return result.fold(
      ifLeft: Left.new,
      ifRight: (final prompts) {
        if (prompts.isEmpty) {
          return const Left(
            ServerFailure(message: 'No writing prompts available'),
          );
        }
        var filteredPrompts = prompts;
        if (params.difficultyLevel != null) {
          filteredPrompts = [
            ...filteredPrompts.where(
              (final prompt) =>
                  prompt.difficultyLevel?.toLowerCase() ==
                  params.difficultyLevel!.toLowerCase(),
            ),
          ];
        }
        if (params.topic != null) {
          filteredPrompts = [
            ...filteredPrompts.where(
              (final prompt) =>
                  prompt.topic?.toLowerCase() == params.topic!.toLowerCase(),
            ),
          ];
        }

        if (filteredPrompts.isEmpty) {
          return const Left(
            ServerFailure(
              message: 'No prompts found matching the specified criteria',
            ),
          );
        }

        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % filteredPrompts.length;
        return Right(filteredPrompts[randomIndex]);
      },
    );
  }
}
