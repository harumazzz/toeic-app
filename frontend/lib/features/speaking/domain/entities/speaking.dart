import 'package:freezed_annotation/freezed_annotation.dart';

part 'speaking.freezed.dart';

@freezed
sealed class SpeakingRequest with _$SpeakingRequest {
    const factory SpeakingRequest({
      required final int userId,
      required final DateTime endTime,
      required final String sessionTopic,
      required final DateTime startTime,
    }) = _SpeakingRequest;
}

@freezed
sealed class Speaking with _$Speaking {
    const factory Speaking({
      required final int id,
      required final int userId,
      required final String sessionTopic,
      required final DateTime endTime,
      required final DateTime startTime,
      required final DateTime updatedAt,
    }) = _Speaking;
}

@freezed
sealed class SpeakingTurn with _$SpeakingTurn {
    const factory SpeakingTurn({
      required final AiEvaluation aiEvaluation,
      required final int aiScore,
      required final String audioRecordingPath,
      required final int id,
      required final int sessionId,
      required final String speakerType,
      required final String textSpoken,
      required final DateTime timestamp,
    }) = _SpeakingTurn;
}

@freezed
sealed class SpeakingTurnRequest with _$SpeakingTurnRequest {
    const factory SpeakingTurnRequest({
      required final AiEvaluation aiEvaluation,
      required final int aiScore,
      required final String audioRecordingPath,
      required final int sessionId,
      required final String speakerType,
      required final String textSpoken,
      required final DateTime timestamp,
    }) = _SpeakingTurnRequest;
}

@freezed
sealed class AiEvaluation with _$AiEvaluation {
    const factory AiEvaluation(

    ) = _AiEvaluation;
}
