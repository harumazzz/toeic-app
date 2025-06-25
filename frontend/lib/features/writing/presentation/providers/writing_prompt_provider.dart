import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/use_cases/use_case.dart';
import '../../domain/entities/writing_prompt.dart';
import '../../domain/use_cases/get_writing_prompts_use_case.dart';
import '../../domain/use_cases/writing_prompt_usecases.dart';

part 'writing_prompt_provider.freezed.dart';
part 'writing_prompt_provider.g.dart';

@freezed
sealed class WritingPromptState with _$WritingPromptState {
  const factory WritingPromptState.initial() = WritingPromptInitial;
  const factory WritingPromptState.loading() = WritingPromptLoading;
  const factory WritingPromptState.loaded({
    required final List<WritingPrompt> prompts,
  }) = WritingPromptLoaded;
  const factory WritingPromptState.error({
    required final String message,
  }) = WritingPromptError;
}

@riverpod
class WritingPromptController extends _$WritingPromptController {
  @override
  WritingPromptState build() => const WritingPromptState.initial();

  Future<void> loadWritingPrompts() async {
    state = const WritingPromptState.loading();

    final getWritingPromptsUseCase = ref.read(getWritingPromptsUseCaseProvider);
    final result = await getWritingPromptsUseCase(const NoParams());

    state = result.fold(
      ifLeft:
          (final failure) => WritingPromptState.error(
            message: failure.message,
          ),
      ifRight:
          (final prompts) => WritingPromptState.loaded(
            prompts: prompts,
          ),
    );
  }

  void reset() {
    state = const WritingPromptState.initial();
  }
}

@freezed
sealed class SingleWritingPromptState with _$SingleWritingPromptState {
  const factory SingleWritingPromptState.initial() = SingleWritingPromptInitial;
  const factory SingleWritingPromptState.loading() = SingleWritingPromptLoading;
  const factory SingleWritingPromptState.loaded({
    required final WritingPrompt prompt,
  }) = SingleWritingPromptLoaded;
  const factory SingleWritingPromptState.error({
    required final String message,
  }) = SingleWritingPromptError;
}

@riverpod
class SingleWritingPromptController extends _$SingleWritingPromptController {
  @override
  SingleWritingPromptState build() => const SingleWritingPromptState.initial();

  Future<void> loadWritingPrompt(final int promptId) async {
    state = const SingleWritingPromptState.loading();

    final getWritingPromptUseCase = ref.read(getWritingPromptUseCaseProvider);
    final result = await getWritingPromptUseCase(promptId);

    state = result.fold(
      ifLeft:
          (final failure) => SingleWritingPromptState.error(
            message: failure.message,
          ),
      ifRight:
          (final prompt) => SingleWritingPromptState.loaded(
            prompt: prompt,
          ),
    );
  }

  void reset() {
    state = const SingleWritingPromptState.initial();
  }
}
