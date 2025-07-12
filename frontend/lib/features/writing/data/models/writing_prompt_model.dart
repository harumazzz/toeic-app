import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/writing_prompt.dart';

part 'writing_prompt_model.freezed.dart';
part 'writing_prompt_model.g.dart';

@freezed
abstract class WritingPromptModel with _$WritingPromptModel {
  const factory WritingPromptModel({
    required final int id,
    @JsonKey(name: 'user_id') final int? userId,
    @JsonKey(name: 'prompt_text') required final String promptText,
    final String? topic,
    @JsonKey(name: 'difficulty_level') final String? difficultyLevel,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _WritingPromptModel;

  factory WritingPromptModel.fromJson(final Map<String, dynamic> json) =>
      _$WritingPromptModelFromJson(json);
}

extension WritingPromptModelExtension on WritingPromptModel {
  WritingPrompt toEntity() => WritingPrompt(
    id: id,
    userId: userId,
    promptText: promptText,
    topic: topic,
    difficultyLevel: difficultyLevel,
    createdAt: createdAt,
  );
}

@freezed
abstract class WritingPromptRequestModel with _$WritingPromptRequestModel {
  const factory WritingPromptRequestModel({
    @JsonKey(name: 'user_id') final int? userId,
    @JsonKey(name: 'prompt_text') required final String promptText,
    final String? topic,
    @JsonKey(name: 'difficulty_level') final String? difficultyLevel,
  }) = _WritingPromptRequestModel;

  factory WritingPromptRequestModel.fromJson(final Map<String, dynamic> json) =>
      _$WritingPromptRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension WritingPromptRequestExtension on WritingPromptRequest {
  WritingPromptRequestModel toModel() => WritingPromptRequestModel(
    userId: userId,
    promptText: promptText,
    topic: topic,
    difficultyLevel: difficultyLevel,
  );
}

Map<String, dynamic> serializeWritingPromptRequestModel(
  final WritingPromptRequestModel object,
) => object.toJson();
