import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/text_analyze.dart';
import '../../domain/entities/user_writing.dart';
import '../../domain/use_cases/analyze_usecases.dart';
import '../../domain/use_cases/create_user_writing_use_case.dart';
import '../../domain/use_cases/get_user_writings_by_prompt_use_case.dart';
import '../../domain/use_cases/user_writing_usecases.dart'
    hide createUserWritingUseCaseProvider;

part 'user_writing_provider.freezed.dart';
part 'user_writing_provider.g.dart';

@freezed
sealed class UserWritingState with _$UserWritingState {
  const factory UserWritingState.initial() = UserWritingInitial;
  const factory UserWritingState.loading() = UserWritingLoading;
  const factory UserWritingState.loaded({
    required final List<UserWriting> writings,
  }) = UserWritingLoaded;
  const factory UserWritingState.error({
    required final String message,
  }) = UserWritingError;
}

@freezed
sealed class UserWritingSubmissionState with _$UserWritingSubmissionState {
  const factory UserWritingSubmissionState.initial() =
      UserWritingSubmissionInitial;
  const factory UserWritingSubmissionState.submitting() =
      UserWritingSubmissionSubmitting;
  const factory UserWritingSubmissionState.submitted({
    required final UserWriting writing,
  }) = UserWritingSubmissionSubmitted;
  const factory UserWritingSubmissionState.error({
    required final String message,
  }) = UserWritingSubmissionError;
}

@freezed
sealed class UserWritingAnalysisState with _$UserWritingAnalysisState {
  const factory UserWritingAnalysisState.initial() = UserWritingAnalysisInitial;
  const factory UserWritingAnalysisState.loading() = UserWritingAnalysisLoading;
  const factory UserWritingAnalysisState.loaded({
    required final TextAnalyze data,
  }) = UserWritingAnalysisLoaded;
  const factory UserWritingAnalysisState.error({
    required final String message,
  }) = UserWritingAnalysisError;
}

@riverpod
class UserWritingAnalysisController extends _$UserWritingAnalysisController {
  @override
  UserWritingAnalysisState build() => const UserWritingAnalysisState.initial();

  Future<void> analyzeWriting(
    final TextAnalyzeRequest request,
  ) async {
    if (state is UserWritingAnalysisLoading) {
      return;
    }
    state = const UserWritingAnalysisState.loading();

    final analyzeTextUseCase = ref.read(analyzeTextProvider);
    final result = await analyzeTextUseCase(request);

    state = result.fold(
      ifLeft: (final failure) => UserWritingAnalysisState.error(
        message: failure.message,
      ),
      ifRight: (final data) => UserWritingAnalysisState.loaded(
        data: data,
      ),
    );
  }
}

@riverpod
class UserWritingController extends _$UserWritingController {
  @override
  UserWritingState build() => const UserWritingState.initial();

  Future<void> loadUserWritingsByPrompt(final int promptId) async {
    state = const UserWritingState.loading();

    final getUserWritingsByPromptUseCase = ref.read(
      getUserWritingsByPromptUseCaseProvider,
    );
    final result = await getUserWritingsByPromptUseCase(promptId);

    state = result.fold(
      ifLeft: (final failure) => UserWritingState.error(
        message: failure.message,
      ),
      ifRight: (final writings) => UserWritingState.loaded(
        writings: writings,
      ),
    );
  }

  void reset() {
    state = const UserWritingState.initial();
  }
}

@riverpod
class UserWritingSubmissionController
    extends _$UserWritingSubmissionController {
  @override
  UserWritingSubmissionState build() =>
      const UserWritingSubmissionState.initial();

  Future<void> submitWriting(
    final UserWritingRequest request,
  ) async {
    state = const UserWritingSubmissionState.submitting();

    final createUserWritingUseCase = ref.read(createUserWritingUseCaseProvider);
    final result = await createUserWritingUseCase(request);

    state = result.fold(
      ifLeft: (final failure) => UserWritingSubmissionState.error(
        message: failure.message,
      ),
      ifRight: (final writing) => UserWritingSubmissionState.submitted(
        writing: writing,
      ),
    );
  }

  void reset() {
    state = const UserWritingSubmissionState.initial();
  }
}

@riverpod
class UserWritingsByUserController extends _$UserWritingsByUserController {
  @override
  UserWritingState build() => const UserWritingState.initial();

  Future<void> loadUserWritingsByUserId(final int userId) async {
    state = const UserWritingState.loading();

    final listUserWritingsByUserIdUseCase = ref.read(
      listUserWritingsByUserIdUseCaseProvider,
    );
    final result = await listUserWritingsByUserIdUseCase(userId);

    state = result.fold(
      ifLeft: (final failure) => UserWritingState.error(
        message: failure.message,
      ),
      ifRight: (final writings) => UserWritingState.loaded(
        writings: writings,
      ),
    );
  }

  Future<bool> deleteWriting(final int writingId, final int userId) async {
    final deleteUserWritingUseCase = ref.read(deleteUserWritingUseCaseProvider);
    final result = await deleteUserWritingUseCase(writingId);

    return result.fold(
      ifLeft: (_) => false,
      ifRight: (_) {
        loadUserWritingsByUserId(userId);
        return true;
      },
    );
  }
}
