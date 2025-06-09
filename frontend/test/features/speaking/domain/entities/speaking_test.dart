import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/speaking/domain/entities/speaking.dart';

void main() {
  group('Speaking Entity Tests', () {
    final testDateTime = DateTime(2024);

    test('should create a valid SpeakingRequest instance', () {
      final request = SpeakingRequest(
        userId: 1,
        endTime: testDateTime,
        sessionTopic: 'Test Topic',
        startTime: testDateTime,
      );

      expect(request.userId, 1);
      expect(request.endTime, testDateTime);
      expect(request.sessionTopic, 'Test Topic');
      expect(request.startTime, testDateTime);
    });

    test('should create a valid Speaking instance', () {
      final speaking = Speaking(
        id: 1,
        userId: 1,
        sessionTopic: 'Test Topic',
        endTime: testDateTime,
        startTime: testDateTime,
        updatedAt: testDateTime,
      );

      expect(speaking.id, 1);
      expect(speaking.userId, 1);
      expect(speaking.sessionTopic, 'Test Topic');
      expect(speaking.endTime, testDateTime);
      expect(speaking.startTime, testDateTime);
      expect(speaking.updatedAt, testDateTime);
    });

    test('should create a valid SpeakingTurn instance', () {
      final turn = SpeakingTurn(
        aiEvaluation: const AiEvaluation(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        id: 1,
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      expect(turn.aiEvaluation, const AiEvaluation());
      expect(turn.aiScore, 85);
      expect(turn.audioRecordingPath, '/path/to/audio.mp3');
      expect(turn.id, 1);
      expect(turn.sessionId, 1);
      expect(turn.speakerType, 'user');
      expect(turn.textSpoken, 'Hello, how are you?');
      expect(turn.timestamp, testDateTime);
    });

    test('should create a valid SpeakingTurnRequest instance', () {
      final request = SpeakingTurnRequest(
        aiEvaluation: const AiEvaluation(),
        aiScore: 85,
        audioRecordingPath: '/path/to/audio.mp3',
        sessionId: 1,
        speakerType: 'user',
        textSpoken: 'Hello, how are you?',
        timestamp: testDateTime,
      );

      expect(request.aiEvaluation, const AiEvaluation());
      expect(request.aiScore, 85);
      expect(request.audioRecordingPath, '/path/to/audio.mp3');
      expect(request.sessionId, 1);
      expect(request.speakerType, 'user');
      expect(request.textSpoken, 'Hello, how are you?');
      expect(request.timestamp, testDateTime);
    });

    test('should create a valid AiEvaluation instance', () {
      const evaluation = AiEvaluation();
      expect(evaluation, const AiEvaluation());
    });
  });
}
