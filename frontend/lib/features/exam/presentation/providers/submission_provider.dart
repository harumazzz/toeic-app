import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/result.dart';
import '../../domain/usecases/submit_answer.dart';

part 'submission_provider.g.dart';
part 'submission_provider.freezed.dart';

@freezed
sealed class SubmissionState with _$SubmissionState {
  const factory SubmissionState.initial() = SubmissionInitial;
  const factory SubmissionState.loading() = SubmissionLoading;
  const factory SubmissionState.success(
    final SubmittedAnswer result,
  ) = SubmissionSuccess;
  const factory SubmissionState.error(final String message) = SubmissionError;
}

@riverpod
class SubmissionNotifier extends _$SubmissionNotifier {
  @override
  SubmissionState build() => const SubmissionState.initial();

  Future<void> submitAnswers({
    required final int attemptId,
    required final List<SubmitAnswer> answers,
  }) async {
    state = const SubmissionState.loading();

    try {
      final submitAnswerUseCase = ref.read(submitAnswerProvider);

      final request = SubmitAnswersRequest(
        attemptId: attemptId,
        answers: answers,
      );

      final result = await submitAnswerUseCase.call(request);

      result.fold(
        ifLeft: (final failure) =>
            state = SubmissionState.error(failure.message),
        ifRight: (final submittedAnswer) =>
            state = SubmissionState.success(submittedAnswer),
      );
    } catch (e) {
      state = SubmissionState.error('Failed to submit answers: $e');
    }
  }

  void reset() {
    state = const SubmissionState.initial();
  }
}
