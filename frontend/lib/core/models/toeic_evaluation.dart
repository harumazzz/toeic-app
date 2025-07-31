import 'package:freezed_annotation/freezed_annotation.dart';

part 'toeic_evaluation.freezed.dart';
part 'toeic_evaluation.g.dart';

/// TOEIC speaking evaluation result with comprehensive scoring
@freezed
sealed class ToeicEvaluation with _$ToeicEvaluation {
  const factory ToeicEvaluation({
    required final int score,
    required final String feedback,
    required final int pronunciationScore,
    required final int fluencyScore,
    required final int grammarScore,
    required final int vocabularyScore,
    required final int contentRelevanceScore,
    required final String strengths,
    required final String improvements,
    required final List<String> grammarErrors,
    required final List<String> vocabularySuggestions,
    required final List<String> speakingTips,
    required final String estimatedToeicLevel,
    required final int confidenceLevel,
    // Optional fields for specific test parts
    final int? relevanceScore,
    final int? completenessScore,
    final int? answerAccuracy,
    final int? explanationQuality,
    final int? languageUse,
    final int? grammarUnderstanding,
    final int? communicationClarity,
    final bool? correctAnswerGiven,
    final String? explanationAccuracy,
    final List<String>? alternativeExplanations,
    final List<String>? relatedGrammarPoints,
    final List<String>? studyRecommendations,
    final String? metalinguisticAwareness,
    final List<String>? followUpSuggestions,
    final String? culturalAppropriateness,
    final List<String>? conversationTips,
  }) = _ToeicEvaluation;

  factory ToeicEvaluation.fromJson(final Map<String, dynamic> json) =>
      _$ToeicEvaluationFromJson(json);
}

/// Study plan for TOEIC improvement
@freezed
sealed class StudyPlan with _$StudyPlan {
  const factory StudyPlan({
    required final String currentLevelAssessment,
    required final List<String> strengths,
    required final List<String> priorityAreas,
    required final WeeklyStudyPlan weeklyPlan,
    required final PracticeFocus practiceFocus,
    required final List<String> progressMilestones,
    required final String estimatedTimeline,
    required final List<String> motivationTips,
    required final List<String> recommendedResources,
  }) = _StudyPlan;

  factory StudyPlan.fromJson(final Map<String, dynamic> json) =>
      _$StudyPlanFromJson(json);
}

/// Weekly study plan structure
@freezed
sealed class WeeklyStudyPlan with _$WeeklyStudyPlan {
  const factory WeeklyStudyPlan({
    required final List<String> week1,
    required final List<String> week2,
    required final List<String> week3,
    required final List<String> week4,
  }) = _WeeklyStudyPlan;

  factory WeeklyStudyPlan.fromJson(final Map<String, dynamic> json) =>
      _$WeeklyStudyPlanFromJson(json);
}

/// Practice focus areas
@freezed
sealed class PracticeFocus with _$PracticeFocus {
  const factory PracticeFocus({
    required final List<String> grammar,
    required final List<String> vocabulary,
    required final List<String> speaking,
    required final List<String> listening,
  }) = _PracticeFocus;

  factory PracticeFocus.fromJson(final Map<String, dynamic> json) =>
      _$PracticeFocusFromJson(json);
}

/// TOEIC Part 5 question data
@freezed
sealed class ToeicPart5Question with _$ToeicPart5Question {
  const factory ToeicPart5Question({
    required final String question,
    required final String options,
    required final String correct,
    required final String explanation,
    final String? topic,
    final List<String>? difficultyIndicators,
    final List<String>? learningObjectives,
  }) = _ToeicPart5Question;

  factory ToeicPart5Question.fromJson(final Map<String, dynamic> json) =>
      _$ToeicPart5QuestionFromJson(json);
}

/// Adaptive TOEIC question data
@freezed
sealed class AdaptiveToeicQuestion with _$AdaptiveToeicQuestion {
  const factory AdaptiveToeicQuestion({
    required final String question,
    required final String topic,
    required final List<String> difficultyIndicators,
    required final List<String> learningObjectives,
    final String? options,
    final String? correct,
    final String? explanation,
  }) = _AdaptiveToeicQuestion;

  factory AdaptiveToeicQuestion.fromJson(final Map<String, dynamic> json) =>
      _$AdaptiveToeicQuestionFromJson(json);
}
