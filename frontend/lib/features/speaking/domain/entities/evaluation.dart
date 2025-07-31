import 'package:freezed_annotation/freezed_annotation.dart';

part 'evaluation.freezed.dart';
part 'evaluation.g.dart';

@freezed
sealed class SpeakingEvaluation with _$SpeakingEvaluation {
  const factory SpeakingEvaluation({
    @JsonKey(name: 'overall_score') required final int overallScore,
    final String? feedback,
    @JsonKey(name: 'pronunciation_score') final int? pronunciationScore,
    @JsonKey(name: 'fluency_score') final int? fluencyScore,
    @JsonKey(name: 'grammar_score') final int? grammarScore,
    @JsonKey(name: 'vocabulary_score') final int? vocabularyScore,
    @JsonKey(name: 'content_score') final int? contentScore,
    final List<String>? suggestions,
    @JsonKey(name: 'confidence_level') final double? confidenceLevel,
    @JsonKey(name: 'processing_time_ms') final int? processingTimeMs,
  }) = _SpeakingEvaluation;

  factory SpeakingEvaluation.fromJson(final Map<String, dynamic> json) =>
      _$SpeakingEvaluationFromJson(json);
}
