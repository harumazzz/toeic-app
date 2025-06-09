import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/speaking/data/models/speaking_model.dart';
import 'package:learn/features/speaking/domain/entities/speaking.dart';

void main() {
  group('Speaking Model Tests', () {
    final testDateTime = DateTime(2024);

    test('should create a valid SpeakingModel instance', () {
      final model = SpeakingModel(
        id: 1,
        userId: 1,
        sessionTopic: 'Test Topic',
        endTime: testDateTime,
        startTime: testDateTime,
        updatedAt: testDateTime,
      );

      expect(model.id, 1);
      expect(model.userId, 1);
      expect(model.sessionTopic, 'Test Topic');
      expect(model.endTime, testDateTime);
      expect(model.startTime, testDateTime);
      expect(model.updatedAt, testDateTime);
    });

    test('should create a valid SpeakingRequestModel instance', () {
      final model = SpeakingRequestModel(
        userId: 1,
        endTime: testDateTime.toIso8601String(),
        sessionTopic: 'Test Topic',
        startTime: testDateTime.toIso8601String(),
      );

      expect(model.userId, 1);
      expect(model.endTime, testDateTime.toIso8601String());
      expect(model.sessionTopic, 'Test Topic');
      expect(model.startTime, testDateTime.toIso8601String());
    });

    test('should create a valid SpeakingTurnModel instance', () {
      final model = SpeakingTurnModel(
        aiEvaluation: const AiEvaluationModel(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        id: 1,
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      expect(model.aiEvaluation, const AiEvaluationModel());
      expect(model.aiScore, 85);
      expect(model.audioRecordingPath, '/path/to/audio.mp3');
      expect(model.id, 1);
      expect(model.sessionId, 1);
      expect(model.speakerType, 'user');
      expect(model.textSpoken, 'Hello, how are you?');
      expect(model.timestamp, testDateTime);
    });

    test('should create a valid SpeakingTurnRequestModel instance', () {
      final model = SpeakingTurnRequestModel(
        aiEvaluation: const AiEvaluationModel(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      expect(model.aiEvaluation, const AiEvaluationModel());
      expect(model.aiScore, 85);
      expect(model.audioRecordingPath, '/path/to/audio.mp3');
      expect(model.sessionId, 1);
      expect(model.speakerType, 'user');
      expect(model.textSpoken, 'Hello, how are you?');
      expect(model.timestamp, testDateTime);
    });

    test('should create a valid AiEvaluationModel instance', () {
      const model = AiEvaluationModel();
      expect(model, const AiEvaluationModel());
    });

    test('should convert SpeakingModel to entity', () {
      final model = SpeakingModel(
        id: 1,
        userId: 1,
        sessionTopic: 'Test Topic',
        endTime: testDateTime,
        startTime: testDateTime,
        updatedAt: testDateTime,
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.userId, model.userId);
      expect(entity.sessionTopic, model.sessionTopic);
      expect(entity.endTime, model.endTime);
      expect(entity.startTime, model.startTime);
      expect(entity.updatedAt, model.updatedAt);
    });

    test('should convert SpeakingTurnModel to entity', () {
      final model = SpeakingTurnModel(
        aiEvaluation: const AiEvaluationModel(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        id: 1,
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      final entity = model.toEntity();

      expect(entity.aiEvaluation, const AiEvaluation());
      expect(entity.aiScore, model.aiScore);
      expect(entity.audioRecordingPath, model.audioRecordingPath);
      expect(entity.id, model.id);
      expect(entity.sessionId, model.sessionId);
      expect(entity.speakerType, model.speakerType);
      expect(entity.textSpoken, model.textSpoken);
      expect(entity.timestamp, model.timestamp);
    });

    test('should convert SpeakingRequest to model', () {
      final request = SpeakingRequest(
        userId: 1,
        endTime: testDateTime,
        sessionTopic: 'Test Topic',
        startTime: testDateTime,
      );

      final model = request.toModel();

      expect(model.userId, request.userId);
      expect(model.endTime, request.endTime.toIso8601String());
      expect(model.sessionTopic, request.sessionTopic);
      expect(model.startTime, request.startTime.toIso8601String());
    });

    test('should convert SpeakingTurnRequest to model', () {
      final request = SpeakingTurnRequest(
        aiEvaluation: const AiEvaluation(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      final model = request.toModel();

      expect(model.aiEvaluation, const AiEvaluationModel());
      expect(model.aiScore, request.aiScore);
      expect(model.audioRecordingPath, request.audioRecordingPath);
      expect(model.sessionId, request.sessionId);
      expect(model.speakerType, request.speakerType);
      expect(model.textSpoken, request.textSpoken);
      expect(model.timestamp, request.timestamp);
    });
  });
}
