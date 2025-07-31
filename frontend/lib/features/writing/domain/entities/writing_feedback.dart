import 'package:freezed_annotation/freezed_annotation.dart';

part 'writing_feedback.freezed.dart';
part 'writing_feedback.g.dart';

@freezed
sealed class WritingFeedback with _$WritingFeedback {
  const factory WritingFeedback({
    @JsonKey(name: 'overall_score') required final int overallScore,
    final String? feedback,
    @JsonKey(name: 'grammar_score') final int? grammarScore,
    @JsonKey(name: 'vocabulary_score') final int? vocabularyScore,
    @JsonKey(name: 'organization_score') final int? organizationScore,
    @JsonKey(name: 'content_score') final int? contentScore,
    @JsonKey(name: 'task_achievement_score') final int? taskAchievementScore,
    @JsonKey(name: 'grammar_feedback') final String? grammarFeedback,
    @JsonKey(name: 'vocabulary_feedback') final String? vocabularyFeedback,
    @JsonKey(name: 'organization_feedback') final String? organizationFeedback,
    @JsonKey(name: 'content_feedback') final String? contentFeedback,
    final List<String>? suggestions,
    @JsonKey(name: 'strengths') final List<String>? strengths,
    @JsonKey(name: 'areas_for_improvement')
    final List<String>? areasForImprovement,
    @JsonKey(name: 'toeic_band') final String? toeicBand,
    @JsonKey(name: 'estimated_score') final int? estimatedScore,
    @JsonKey(name: 'confidence_level') final double? confidenceLevel,
  }) = _WritingFeedback;

  factory WritingFeedback.fromJson(final Map<String, dynamic> json) =>
      _$WritingFeedbackFromJson(json);
}
