import 'package:freezed_annotation/freezed_annotation.dart';

part 'writing_prompt.freezed.dart';

@freezed
abstract class WritingPrompt with _$WritingPrompt {
  const factory WritingPrompt({
    required final int id,
    final int? userId,
    required final String promptText,
    final String? topic,
    final String? difficultyLevel,
    required final DateTime createdAt,
  }) = _WritingPrompt;
}

@freezed
abstract class WritingPromptRequest with _$WritingPromptRequest {
  const factory WritingPromptRequest({
    final int? userId,
    required final String promptText,
    final String? topic,
    final String? difficultyLevel,
  }) = _WritingPromptRequest;
}
