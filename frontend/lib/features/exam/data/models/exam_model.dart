import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/exam.dart';

part 'exam_model.freezed.dart';
part 'exam_model.g.dart';

@freezed
abstract class ExamModel with _$ExamModel {
  const factory ExamModel({
    @JsonKey(name: 'exam_id') required final int examId,
    @JsonKey(name: 'exam_title') required final String examTitle,
    required final List<PartModel> parts,
    @JsonKey(name: 'total_questions') required final int totalQuestions,
  }) = _ExamModel;

  factory ExamModel.fromJson(final Map<String, dynamic> json) =>
      _$ExamModelFromJson(json);
}

@freezed
abstract class PartModel with _$PartModel {
  const factory PartModel({
    @JsonKey(name: 'part_id') required final int partId,
    required final String title,
    required final List<ContentModel> contents,
  }) = _PartModel;

  factory PartModel.fromJson(final Map<String, dynamic> json) =>
      _$PartModelFromJson(json);
}

@freezed
abstract class ContentModel with _$ContentModel {
  const factory ContentModel({
    @JsonKey(name: 'content_id') required final int contentId,
    @JsonKey(name: 'description') required final String description,
    @JsonKey(name: 'type') required final String type,
    @JsonKey(name: 'questions') required final List<QuestionModel> questions,
  }) = _ContentModel;

  factory ContentModel.fromJson(final Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
}

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'content_id') required final int contentId,
    required final String title,
    required final String explanation,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'media_url') final String? mediaUrl,
    required final String? keywords,
    @JsonKey(name: 'possible_answers')
    required final List<String> possibleAnswers,
    @JsonKey(name: 'true_answer') required final String trueAnswer,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(final Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}

@freezed
abstract class UserAnswerModel with _$UserAnswerModel {
  const factory UserAnswerModel({
    @JsonKey(name: 'answer_time') required final String answerTime,
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'created_at') required final String createdAt,
    required final String explanation,
    @JsonKey(name: 'is_correct') required final bool isCorrect,
    @JsonKey(name: 'possible_answers')
    required final List<String> possibleAnswers,
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'question_title') required final String questionTitle,
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
    @JsonKey(name: 'true_answer') required final String trueAnswer,
    @JsonKey(name: 'user_answer_id') required final int userAnswerId,
  }) = _UserAnswerModel;

  factory UserAnswerModel.fromJson(final Map<String, dynamic> json) =>
      _$UserAnswerModelFromJson(json);
}

@freezed
abstract class UserAnswerResponseModel with _$UserAnswerResponseModel {
  const factory UserAnswerResponseModel({
    required final List<UserAnswerModel> answers,
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'correct_count') required final int correctCount,
    @JsonKey(name: 'total_answered') required final int totalAnswered,
  }) = _UserAnswerResponseModel;

  factory UserAnswerResponseModel.fromJson(final Map<String, dynamic> json) =>
      _$UserAnswerResponseModelFromJson(json);
}

@freezed
abstract class ExamAttemptModel with _$ExamAttemptModel {
  const factory ExamAttemptModel({
    @JsonKey(name: 'attempt_id') required final int attemptId,
    @JsonKey(name: 'created_at') required final String createdAt,
    @JsonKey(name: 'end_time') required final String endTime,
    @JsonKey(name: 'exam_id') required final int examId,
    required final String score,
    @JsonKey(name: 'start_time') required final String startTime,
    required final String status,
    @JsonKey(name: 'updated_at') required final String updatedAt,
    @JsonKey(name: 'user_id') required final int userId,
  }) = _ExamAttemptModel;

  factory ExamAttemptModel.fromJson(final Map<String, dynamic> json) =>
      _$ExamAttemptModelFromJson(json);
}

@freezed
abstract class ExamModelRequest with _$ExamModelRequest {
  const factory ExamModelRequest({
    @JsonKey(name: 'exam_id') required final int examId,
  }) = _ExamModelRequest;

  factory ExamModelRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$ExamModelRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    @JsonKey(name: 'answers') required final List<SelectedAnswerModel> answers,
    @JsonKey(name: 'attempt_id') required final int attemptId,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$AnswerModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class SelectedAnswerModel with _$SelectedAnswerModel {
  const factory SelectedAnswerModel({
    @JsonKey(name: 'question_id') required final int questionId,
    @JsonKey(name: 'selected_answer') required final String selectedAnswer,
  }) = _SelectedAnswerModel;

  factory SelectedAnswerModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SelectedAnswerModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class ExamStatsModel with _$ExamStatsModel {
  const factory ExamStatsModel({
    @JsonKey(name: 'abandoned_attempts') required final int abandonedAttempts,
    @JsonKey(name: 'average_score') required final String averageScore,
    @JsonKey(name: 'completed_attempts') required final int completedAttempts,
    @JsonKey(name: 'highest_score') required final String highestScore,
    @JsonKey(name: 'in_progress_attempts')
    required final int inProgressAttempts,
    @JsonKey(name: 'lowest_score') required final String lowestScore,
    @JsonKey(name: 'total_attempts') required final int totalAttempts,
  }) = _ExamStatsModel;

  factory ExamStatsModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ExamStatsModelFromJson(json);
}

@freezed
abstract class UpdateExamAttemptModel with _$UpdateExamAttemptModel {
  const factory UpdateExamAttemptModel({
    @JsonKey(name: 'score') required final String score,
    @JsonKey(name: 'status') required final String status,
  }) = _UpdateExamAttemptModel;

  factory UpdateExamAttemptModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UpdateExamAttemptModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension UpdateExamAttemptExtension on UpdateExamAttempt {
  UpdateExamAttemptModel toModel() => UpdateExamAttemptModel(
    score: score,
    status: status,
  );
}

extension ExamModelExtension on ExamModel {
  Exam toEntity() => Exam(
    examId: examId,
    examTitle: examTitle,
    parts: [...parts.map((final part) => part.toEntity())],
    totalQuestions: totalQuestions,
  );
}

extension ExamStatsModelExtension on ExamStatsModel {
  ExamStats toEntity() => ExamStats(
    abandonedAttempts: abandonedAttempts,
    averageScore: averageScore,
    completedAttempts: completedAttempts,
    highestScore: highestScore,
    inProgressAttempts: inProgressAttempts,
    lowestScore: lowestScore,
    totalAttempts: totalAttempts,
  );
}

extension ExamRequestExtension on ExamRequest {
  ExamModelRequest toModel() => ExamModelRequest(
    examId: examId,
  );
}

extension PartModelExtension on PartModel {
  Part toEntity() => Part(
    partId: partId,
    title: title,
    contents: [...contents.map((final content) => content.toEntity())],
  );
}

extension ContentModelExtension on ContentModel {
  Content toEntity() => Content(
    contentId: contentId,
    description: description,
    type: type,
    questions: [...questions.map((final question) => question.toEntity())],
  );
}

extension QuestionModelExtension on QuestionModel {
  Question toEntity() => Question(
    questionId: questionId,
    contentId: contentId,
    title: title,
    explanation: explanation,
    imageUrl: imageUrl,
    mediaUrl: mediaUrl,
    keywords: keywords,
    possibleAnswers: possibleAnswers,
    trueAnswer: trueAnswer,
  );
}

extension UserAnswerModelExtension on UserAnswerModel {
  UserAnswer toEntity() => UserAnswer(
    answerTime: answerTime,
    attemptId: attemptId,
    createdAt: createdAt,
    explanation: explanation,
    isCorrect: isCorrect,
    possibleAnswers: possibleAnswers,
    questionId: questionId,
    questionTitle: questionTitle,
    selectedAnswer: selectedAnswer,
    trueAnswer: trueAnswer,
    userAnswerId: userAnswerId,
  );
}

extension UserAnswerResponseModelExtension on UserAnswerResponseModel {
  UserAnswerResponse toEntity() => UserAnswerResponse(
    answers: [...answers.map((final answer) => answer.toEntity())],
    attemptId: attemptId,
    correctCount: correctCount,
    totalAnswered: totalAnswered,
  );
}

extension ExamAttemptModelExtension on ExamAttemptModel {
  ExamAttempt toEntity() => ExamAttempt(
    attemptId: attemptId,
    createdAt: createdAt,
    endTime: endTime,
    examId: examId,
    score: score,
    startTime: startTime,
    status: status,
    updatedAt: updatedAt,
    userId: userId,
  );
}

extension AnswerExtension on Answer {
  AnswerModel toModel() => AnswerModel(
    answers: [...answers.map((final answer) => answer.toModel())],
    attemptId: attemptId,
  );
}

extension SelectedAnswerExtension on SelectedAnswer {
  SelectedAnswerModel toModel() => SelectedAnswerModel(
    questionId: questionId,
    selectedAnswer: selectedAnswer,
  );
}

Map<String, dynamic> serializeExamModelRequest(
  final ExamModelRequest object,
) => object.toJson();

Map<String, dynamic> serializeUpdateExamAttemptModel(
  final UpdateExamAttemptModel object,
) => object.toJson();
