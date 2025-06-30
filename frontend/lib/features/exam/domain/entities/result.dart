import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
sealed class UserResult with _$UserResult {
  const factory UserResult({
    required final List<Answer> answers,
    required final int attemptId,
    required final List<FailedAnswer> failedAnswers,
    required final Score score,
    required final int totalCorrect,
    required final int totalSubmitted,
  }) = _UserResult;
}

@freezed
sealed class Answer with _$Answer {
  const factory Answer({
    required final String answerTime,
    required final int attemptId,
    required final String createdAt,
    required final bool isCorrect,
    required final int questionId,
    required final String selectedAnswer,
    required final int userAnswerId,
  }) = _Answer;
}

@freezed
sealed class FailedAnswer with _$FailedAnswer {
  const factory FailedAnswer({
    required final String error,
    required final int questionId,
    required final String selectedAnswer,
  }) = _FailedAnswer;
}

@freezed
sealed class Score with _$Score {
  const factory Score({
    required final int attemptId,
    required final int calculatedScore,
    required final int correctAnswers,
    required final int totalQuestions,
  }) = _Score;
}

@freezed
sealed class UserAnswerRequest with _$UserAnswerRequest {
  const factory UserAnswerRequest({
    required final int attemptId,
    required final int questionId,
    required final String selectedAnswer,
  }) = _UserAnswerRequest;
}

@freezed
sealed class UpdateUserAnswerRequest with _$UpdateUserAnswerRequest {
  const factory UpdateUserAnswerRequest({
    required final String selectedAnswer,
  }) = _UpdateUserAnswerRequest;
}

@freezed
sealed class SubmitAnswersRequest with _$SubmitAnswersRequest {
  const factory SubmitAnswersRequest({
    required final int attemptId,
    required final List<SubmitAnswer> answers,
  }) = _SubmitAnswersRequest;
}

@freezed
sealed class SubmitAnswer with _$SubmitAnswer {
  const factory SubmitAnswer({
    required final int questionId,
    required final String selectedAnswer,
  }) = _SubmitAnswer;
}

@freezed
sealed class SubmittedAnswer with _$SubmittedAnswer {
  const factory SubmittedAnswer({
    required final List<SubmitAnswerResult> answers,
    required final int attemptId,
    required final List<FailedSubmitAnswer> failedAnswers,
    required final SubmitScore score,
    required final int totalCorrect,
    required final int totalSubmitted,
  }) = _SubmittedAnswer;
}

@freezed
sealed class SubmitAnswerResult with _$SubmitAnswerResult {
  const factory SubmitAnswerResult({
    required final String answerTime,
    required final int attemptId,
    required final String createdAt,
    required final bool isCorrect,
    required final int questionId,
    required final String selectedAnswer,
    required final int userAnswerId,
  }) = _SubmitAnswerResult;
}

@freezed
sealed class FailedSubmitAnswer with _$FailedSubmitAnswer {
  const factory FailedSubmitAnswer({
    required final String error,
    required final int questionId,
    required final String selectedAnswer,
  }) = _FailedSubmitAnswer;
}

@freezed
sealed class SubmitScore with _$SubmitScore {
  const factory SubmitScore({
    required final int attemptId,
    required final int calculatedScore,
    required final int correctAnswers,
    required final int totalQuestions,
  }) = _SubmitScore;
}
