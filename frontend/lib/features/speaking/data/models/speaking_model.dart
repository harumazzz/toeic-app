import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/speaking.dart';

part 'speaking_model.g.dart';
part 'speaking_model.freezed.dart';

@freezed
abstract class SpeakingModel with _$SpeakingModel {
  const factory SpeakingModel({
    @JsonKey(name: 'end_time') required final DateTime endTime,
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'session_topic') required final String sessionTopic,
    @JsonKey(name: 'start_time') required final DateTime startTime,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
    @JsonKey(name: 'user_id') required final int userId,
  }) = _SpeakingModel;

  factory SpeakingModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SpeakingModelFromJson(json);
}

@freezed
abstract class SpeakingRequestModel with _$SpeakingRequestModel {
  const factory SpeakingRequestModel({
    @JsonKey(name: 'end_time') required final String endTime,
    @JsonKey(name: 'session_topic') required final String sessionTopic,
    @JsonKey(name: 'start_time') required final String startTime,
    @JsonKey(name: 'user_id') required final int userId,
  }) = _SpeakingRequestModel;

  factory SpeakingRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SpeakingRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class SpeakingTurnModel with _$SpeakingTurnModel {
  const factory SpeakingTurnModel({
    @JsonKey(name: 'ai_evaluation')
    required final AiEvaluationModel aiEvaluation,
    @JsonKey(name: 'ai_score') required final int aiScore,
    @JsonKey(name: 'audio_recording_path')
    required final String audioRecordingPath,
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'session_id') required final int sessionId,
    @JsonKey(name: 'speaker_type') required final String speakerType,
    @JsonKey(name: 'text_spoken') required final String textSpoken,
    @JsonKey(name: 'timestamp') required final DateTime timestamp,
  }) = _SpeakingTurnModel;

  factory SpeakingTurnModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SpeakingTurnModelFromJson(json);
}

@freezed
abstract class SpeakingTurnRequestModel with _$SpeakingTurnRequestModel {
  const factory SpeakingTurnRequestModel({
    @JsonKey(name: 'ai_evaluation')
    required final AiEvaluationModel aiEvaluation,
    @JsonKey(name: 'ai_score') required final int aiScore,
    @JsonKey(name: 'audio_recording_path')
    required final String audioRecordingPath,
    @JsonKey(name: 'session_id') required final int sessionId,
    @JsonKey(name: 'speaker_type') required final String speakerType,
    @JsonKey(name: 'text_spoken') required final String textSpoken,
    @JsonKey(name: 'timestamp') required final DateTime timestamp,
  }) = _SpeakingTurnRequestModel;

  factory SpeakingTurnRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SpeakingTurnRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

@freezed
abstract class AiEvaluationModel with _$AiEvaluationModel {
  const factory AiEvaluationModel() = _AiEvaluationModel;

  factory AiEvaluationModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$AiEvaluationModelFromJson(json);
}

extension SpeakingTurnModelExtension on SpeakingTurnModel {
  SpeakingTurn toEntity() => SpeakingTurn(
    aiEvaluation: aiEvaluation.toEntity(),
    aiScore: aiScore,
    audioRecordingPath: audioRecordingPath,
    id: id,
    sessionId: sessionId,
    speakerType: speakerType,
    textSpoken: textSpoken,
    timestamp: timestamp,
  );
}

extension AiEvaluationModelExtension on AiEvaluationModel {
  AiEvaluation toEntity() => const AiEvaluation();
}

extension SpeakingTurnRequestExtension on SpeakingTurnRequest {
  SpeakingTurnRequestModel toModel() => SpeakingTurnRequestModel(
    aiEvaluation: aiEvaluation.toModel(),
    aiScore: aiScore,
    audioRecordingPath: audioRecordingPath,
    sessionId: sessionId,
    speakerType: speakerType,
    textSpoken: textSpoken,
    timestamp: timestamp,
  );
}

extension AiEvaluationExtension on AiEvaluation {
  AiEvaluationModel toModel() => const AiEvaluationModel();
}

extension SpeakingRequestExtension on SpeakingRequest {
  SpeakingRequestModel toModel() => SpeakingRequestModel(
    endTime: endTime.toIso8601String(),
    sessionTopic: sessionTopic,
    startTime: startTime.toIso8601String(),
    userId: userId,
  );
}

extension SpeakModelExtension on SpeakingModel {
  Speaking toEntity() => Speaking(
    id: id,
    userId: userId,
    sessionTopic: sessionTopic,
    endTime: endTime,
    startTime: startTime,
    updatedAt: updatedAt,
  );
}
