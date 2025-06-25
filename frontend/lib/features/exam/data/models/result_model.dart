import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/result.dart';

part 'result_model.freezed.dart';
part 'result_model.g.dart';

@freezed
sealed class UserResultModel with _$UserResultModel {
  const factory UserResultModel({
    @JsonKey(name: 'answers') required final List<AnswerModel> answers,
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'failed_answers')
    required final List<FailedAnswerModel> failedAnswers,
    @JsonKey(name: 'score') required final ScoreModel score,
    @JsonKey(name: 'total_correct') required final int totalCorrect,
    @JsonKey(name: 'total_submitted') required final int totalSubmitted,
  }) = _UserResultModel;

  factory UserResultModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UserResultModelFromJson(json);
}

@freezed
sealed class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    @JsonKey(name: 'answer_time') required final String answerTime,
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'created_at') required final String createdAt,
    @JsonKey(name: 'is_correct') required final bool isCorrect,
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
    @JsonKey(name: 'user_answer_id') required final int userAnswerId,
  }) = _AnswerAnswerModel;

  factory AnswerModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$AnswerModelFromJson(json);
}

@freezed
sealed class FailedAnswerModel with _$FailedAnswerModel {
  const factory FailedAnswerModel({
    @JsonKey(name: 'error') required final String error,
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
  }) = _FailedAnswerModel;

  factory FailedAnswerModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$FailedAnswerModelFromJson(json);
}

@freezed
sealed class ScoreModel with _$ScoreModel {
  const factory ScoreModel({
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'calculated_score') required final int calculatedScore,
    @JsonKey(name: 'correct_answers') required final int correctAnswers,
    @JsonKey(name: 'total_questions') required final int totalQuestions,
  }) = _ScoreModel;

  factory ScoreModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ScoreModelFromJson(json);
}

@freezed
sealed class UserAnswerRequestModel with _$UserAnswerRequestModel {
  const factory UserAnswerRequestModel({
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
  }) = _UserAnswerRequestModel;

  factory UserAnswerRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UserAnswerRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class UpdateUserAnswerRequestModel with _$UpdateUserAnswerRequestModel {
  const factory UpdateUserAnswerRequestModel({
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
  }) = _UpdateUserAnswerRequestModel;

  factory UpdateUserAnswerRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UpdateUserAnswerRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension UpdateUserAnswerRequestExtension on UpdateUserAnswerRequest {
  UpdateUserAnswerRequestModel toModel() => UpdateUserAnswerRequestModel(
    selectedAnswer: selectedAnswer,
  );
}

extension UserAnswerRequestExtension on UserAnswerRequest {
  UserAnswerRequestModel toModel() => UserAnswerRequestModel(
    attemptId: attemptId,
    questionId: questionId,
    selectedAnswer: selectedAnswer,
  );
}

extension UserResultModelExtension on UserResultModel {
  UserResult toEntity() => UserResult(
    answers: [...answers.map((final e) => e.toEntity())],
    attemptId: attemptId,
    failedAnswers: [...failedAnswers.map((final e) => e.toEntity())],
    score: score.toEntity(),
    totalCorrect: totalCorrect,
    totalSubmitted: totalSubmitted,
  );
}

extension AnswerModelExtension on AnswerModel {
  Answer toEntity() => Answer(
    answerTime: answerTime,
    attemptId: attemptId,
    createdAt: createdAt,
    isCorrect: isCorrect,
    questionId: questionId,
    selectedAnswer: selectedAnswer,
    userAnswerId: userAnswerId,
  );
}

extension FailedAnswerModelExtension on FailedAnswerModel {
  FailedAnswer toEntity() => FailedAnswer(
    error: error,
    questionId: questionId,
    selectedAnswer: selectedAnswer,
  );
}

extension ScoreModelExtension on ScoreModel {
  Score toEntity() => Score(
    attemptId: attemptId,
    calculatedScore: calculatedScore,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
  );
}

extension UserResultExtension on UserResult {
  UserResultModel toModel() => UserResultModel(
    answers: [...answers.map((final e) => e.toModel())],
    attemptId: attemptId,
    failedAnswers: [...failedAnswers.map((final e) => e.toModel())],
    score: score.toModel(),
    totalCorrect: totalCorrect,
    totalSubmitted: totalSubmitted,
  );
}

extension AnswerExtension on Answer {
  AnswerModel toModel() => AnswerModel(
    answerTime: answerTime,
    attemptId: attemptId,
    createdAt: createdAt,
    isCorrect: isCorrect,
    questionId: questionId,
    selectedAnswer: selectedAnswer,
    userAnswerId: userAnswerId,
  );
}

extension FailedAnswerExtension on FailedAnswer {
  FailedAnswerModel toModel() => FailedAnswerModel(
    error: error,
    questionId: questionId,
    selectedAnswer: selectedAnswer,
  );
}

extension ScoreExtension on Score {
  ScoreModel toModel() => ScoreModel(
    attemptId: attemptId,
    calculatedScore: calculatedScore,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
  );
}
