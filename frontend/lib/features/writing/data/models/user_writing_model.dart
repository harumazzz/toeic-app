import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_writing.dart';

part 'user_writing_model.freezed.dart';
part 'user_writing_model.g.dart';

@freezed
sealed class UserWritingModel with _$UserWritingModel {
  const factory UserWritingModel({
    required final int id,
    @JsonKey(name: 'user_id') required final int userId,
    @JsonKey(name: 'prompt_id') final int? promptId,
    @JsonKey(name: 'submission_text') required final String submissionText,
    @JsonKey(name: 'ai_feedback') final Map<String, dynamic>? aiFeedback,
    @JsonKey(name: 'ai_score') final double? aiScore,
    @JsonKey(name: 'submitted_at') required final DateTime submittedAt,
    @JsonKey(name: 'evaluated_at') final DateTime? evaluatedAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
  }) = _UserWritingModel;

  factory UserWritingModel.fromJson(final Map<String, dynamic> json) =>
      _$UserWritingModelFromJson(json);
}

@freezed
sealed class UserWritingRequestModel with _$UserWritingRequestModel {
  const factory UserWritingRequestModel({
    @JsonKey(name: 'user_id') required final int userId,
    @JsonKey(name: 'prompt_id') final int? promptId,
    @JsonKey(name: 'submission_text') required final String submissionText,
    @JsonKey(name: 'ai_feedback') final Map<String, dynamic>? aiFeedback,
    @JsonKey(name: 'ai_score') final double? aiScore,
  }) = _UserWritingRequestModel;

  factory UserWritingRequestModel.fromJson(final Map<String, dynamic> json) =>
      _$UserWritingRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
sealed class UserWritingUpdateRequestModel
    with _$UserWritingUpdateRequestModel {
  const factory UserWritingUpdateRequestModel({
    @JsonKey(name: 'submission_text') final String? submissionText,
    @JsonKey(name: 'ai_feedback') final Map<String, dynamic>? aiFeedback,
    @JsonKey(name: 'ai_score') final double? aiScore,
    @JsonKey(name: 'evaluated_at') final DateTime? evaluatedAt,
  }) = _UserWritingUpdateRequestModel;

  factory UserWritingUpdateRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$UserWritingUpdateRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension UserWritingRequestExtension on UserWritingRequest {
  UserWritingRequestModel toModel() => UserWritingRequestModel(
    userId: userId,
    promptId: promptId,
    submissionText: submissionText,
    aiFeedback: aiFeedback,
    aiScore: aiScore,
  );
}

extension UserWritingUpdateRequestExtension on UserWritingUpdateRequest {
  UserWritingUpdateRequestModel toModel() => UserWritingUpdateRequestModel(
    submissionText: submissionText,
    aiFeedback: aiFeedback,
    aiScore: aiScore,
    evaluatedAt: evaluatedAt,
  );
}

extension UserWritingModelExtension on UserWritingModel {
  UserWriting toEntity() => UserWriting(
    id: id,
    userId: userId,
    promptId: promptId,
    submissionText: submissionText,
    aiFeedback: aiFeedback,
    aiScore: aiScore,
    submittedAt: submittedAt,
    evaluatedAt: evaluatedAt,
    updatedAt: updatedAt,
  );
}

Map<String, dynamic> serializeUserWritingRequestModel(
  final UserWritingRequestModel object,
) => object.toJson();

Map<String, dynamic> serializeUserWritingUpdateRequestModel(
  final UserWritingUpdateRequestModel object,
) => object.toJson();
