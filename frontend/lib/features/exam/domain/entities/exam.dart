import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam.freezed.dart';

@freezed
abstract class Exam with _$Exam {
  const factory Exam({
    required final int examId,
    required final String examTitle,
    required final List<Part> parts,
    required final int totalQuestions,
  }) = _Exam;
}

@freezed
abstract class Part with _$Part {
  const factory Part({
    required final int partId,
    required final String title,
    required final List<Content> contents,
  }) = _Part;
}

@freezed
abstract class Content with _$Content {
  const factory Content({
    required final int contentId,
    required final String description,
    required final String type,
    required final List<Question> questions,
  }) = _Content;
}

@freezed
abstract class Question with _$Question {
  const factory Question({
    required final int questionId,
    required final int contentId,
    required final String title,
    required final String explanation,
    final String? imageUrl,
    final String? mediaUrl,
    required final String? keywords,
    required final List<String> possibleAnswers,
    required final String trueAnswer,
  }) = _Question;
}

@freezed
abstract class UserAnswer with _$UserAnswer {
  const factory UserAnswer({
    required final String answerTime,
    required final int attemptId,
    required final String createdAt,
    required final String explanation,
    required final bool isCorrect,
    required final List<String> possibleAnswers,
    required final int questionId,
    required final String questionTitle,
    required final String selectedAnswer,
    required final String trueAnswer,
    required final int userAnswerId,
  }) = _UserAnswer;
}

@freezed
abstract class UserAnswerResponse with _$UserAnswerResponse {
  const factory UserAnswerResponse({
    required final List<UserAnswer> answers,
    required final int attemptId,
    required final int correctCount,
    required final int totalAnswered,
  }) = _UserAnswerResponse;
}

@freezed
abstract class ExamAttempt with _$ExamAttempt {
  const factory ExamAttempt({
    required final int attemptId,
    required final String createdAt,
    required final String endTime,
    required final int examId,
    required final String score,
    required final String startTime,
    required final String status,
    required final String updatedAt,
    required final int userId,
  }) = _ExamAttempt;
}

@freezed
abstract class Answer with _$Answer {
  const factory Answer({
    required final List<SelectedAnswer> answers,
    required final int attemptId,
  }) = _Answer;
}

@freezed
abstract class SelectedAnswer with _$SelectedAnswer {
  const factory SelectedAnswer({
    required final int questionId,
    required final String selectedAnswer,
  }) = _SelectedAnswer;
}

@freezed
abstract class ExamRequest with _$ExamRequest {
  const factory ExamRequest({
    required final int examId,
  }) = _ExamRequest;
}

@freezed
abstract class ExamStats with _$ExamStats {
  const factory ExamStats({
    required final int abandonedAttempts,
    required final String averageScore,
    required final int completedAttempts,
    required final String highestScore,
    required final int inProgressAttempts,
    required final String lowestScore,
    required final int totalAttempts,
  }) = _ExamStats;
}

@freezed
abstract class UpdateExamAttempt with _$UpdateExamAttempt {
  const factory UpdateExamAttempt({
    required final String score,
    required final String status,
  }) = _UpdateExamAttempt;
}
