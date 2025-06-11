// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/writing/domain/entities/user_writing.dart';

void main() {
  group('UserWriting Entity', () {
    final testSubmittedAt = DateTime(2024, 1, 17, 16, 45);
    final testEvaluatedAt = DateTime(2024, 1, 17, 16, 50);
    final testUpdatedAt = DateTime(2024, 1, 17, 16, 50);

    const tAiFeedback = {
      'grammar': 'Good',
      'vocabulary': 'Excellent',
      'coherence': 'Very good',
      'suggestions': [
        'Consider using more transition words',
        'Expand on your main points',
      ],
    };

    final tUserWriting = UserWriting(
      id: 1,
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      aiFeedback: tAiFeedback,
      aiScore: 8.5,
      submittedAt: testSubmittedAt,
      evaluatedAt: testEvaluatedAt,
      updatedAt: testUpdatedAt,
    );

    test('should create UserWriting entity with correct values', () {
      // arrange
      final userWriting = UserWriting(
        id: 1,
        userId: 123,
        promptId: 456,
        submissionText:
            'My favorite hobby is reading because it expands my knowledge and vocabulary.',
        aiFeedback: tAiFeedback,
        aiScore: 8.5,
        submittedAt: testSubmittedAt,
        evaluatedAt: testEvaluatedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(userWriting.id, 1);
      expect(userWriting.userId, 123);
      expect(userWriting.promptId, 456);
      expect(
        userWriting.submissionText,
        'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      );
      expect(userWriting.aiFeedback, tAiFeedback);
      expect(userWriting.aiScore, 8.5);
      expect(userWriting.submittedAt, testSubmittedAt);
      expect(userWriting.evaluatedAt, testEvaluatedAt);
      expect(userWriting.updatedAt, testUpdatedAt);
    });

    test('should create UserWriting entity with optional null values', () {
      // arrange
      final userWriting = UserWriting(
        id: 2,
        userId: 123,
        submissionText: 'Another writing submission.',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(userWriting.id, 2);
      expect(userWriting.userId, 123);
      expect(userWriting.promptId, isNull);
      expect(userWriting.submissionText, 'Another writing submission.');
      expect(userWriting.aiFeedback, isNull);
      expect(userWriting.aiScore, isNull);
      expect(userWriting.submittedAt, testSubmittedAt);
      expect(userWriting.evaluatedAt, isNull);
      expect(userWriting.updatedAt, testUpdatedAt);
    });

    test('should support equality comparison', () {
      // arrange
      final userWriting1 = UserWriting(
        id: 1,
        userId: 123,
        promptId: 456,
        submissionText: 'Test submission',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      final userWriting2 = UserWriting(
        id: 1,
        userId: 123,
        promptId: 456,
        submissionText: 'Test submission',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(userWriting1, userWriting2);
      expect(userWriting1.hashCode, userWriting2.hashCode);
    });

    test('should not be equal when properties differ', () {
      // arrange
      final userWriting1 = UserWriting(
        id: 1,
        userId: 123,
        submissionText: 'Test submission',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      final userWriting2 = UserWriting(
        id: 2,
        userId: 123,
        submissionText: 'Test submission',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(userWriting1, isNot(userWriting2));
      expect(userWriting1.hashCode, isNot(userWriting2.hashCode));
    });

    test('should support copyWith method', () {
      // arrange
      final originalWriting = UserWriting(
        id: 1,
        userId: 123,
        submissionText: 'Original submission',
        aiScore: 7,
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // act
      final updatedWriting = originalWriting.copyWith(
        submissionText: 'Updated submission',
        aiScore: 9,
        evaluatedAt: testEvaluatedAt,
      );

      // assert
      expect(updatedWriting.id, 1);
      expect(updatedWriting.userId, 123);
      expect(updatedWriting.submissionText, 'Updated submission');
      expect(updatedWriting.aiScore, 9.0);
      expect(updatedWriting.evaluatedAt, testEvaluatedAt);
      expect(updatedWriting.submittedAt, testSubmittedAt);
      expect(updatedWriting.updatedAt, testUpdatedAt);
    });

    test('should handle complex AI feedback structure', () {
      // arrange
      const complexFeedback = {
        'overall_score': 8.5,
        'grammar': {
          'score': 8,
          'issues': ['Minor tense inconsistency in paragraph 2'],
          'suggestions': ['Review past perfect usage'],
        },
        'vocabulary': {
          'score': 9,
          'strengths': [
            'Good range of vocabulary',
            'Appropriate academic words',
          ],
          'suggestions': ['Consider using more sophisticated synonyms'],
        },
        'coherence': {
          'score': 8,
          'strengths': [
            'Clear paragraph structure',
            'Good use of linking words',
          ],
          'weaknesses': ['Could improve transitions between ideas'],
        },
        'task_response': {
          'score': 9,
          'comments': 'Fully addresses all parts of the task',
        },
      };

      final userWriting = UserWriting(
        id: 1,
        userId: 123,
        submissionText: 'Complex writing submission',
        aiFeedback: complexFeedback,
        aiScore: 8.5,
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(userWriting.aiFeedback, complexFeedback);
      // ignore: avoid_dynamic_calls
      expect(userWriting.aiFeedback!['grammar']['score'], 8);
      // ignore: avoid_dynamic_calls
      expect(userWriting.aiFeedback!['vocabulary']['strengths'], isA<List>());
    });

    test('should handle AI score validation ranges', () {
      // arrange & act
      final lowScoreWriting = UserWriting(
        id: 1,
        userId: 123,
        submissionText: 'Low score submission',
        aiScore: 2.5,
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      final highScoreWriting = UserWriting(
        id: 2,
        userId: 123,
        submissionText: 'High score submission',
        aiScore: 9.8,
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // assert
      expect(lowScoreWriting.aiScore, 2.5);
      expect(highScoreWriting.aiScore, 9.8);
    });

    test('should handle toString method', () {
      // act
      final stringRepresentation = tUserWriting.toString();

      // assert
      expect(stringRepresentation, contains('UserWriting'));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('userId: 123'));
    });
  });

  group('UserWritingRequest Entity', () {
    const tAiFeedback = {
      'grammar': 'Good',
      'vocabulary': 'Excellent',
      'coherence': 'Very good',
    };

    test('should create UserWritingRequest entity with correct values', () {
      // arrange
      const userWritingRequest = UserWritingRequest(
        userId: 123,
        promptId: 456,
        submissionText:
            'My favorite hobby is reading because it expands my knowledge.',
        aiFeedback: tAiFeedback,
        aiScore: 8.5,
      );

      // assert
      expect(userWritingRequest.userId, 123);
      expect(userWritingRequest.promptId, 456);
      expect(
        userWritingRequest.submissionText,
        'My favorite hobby is reading because it expands my knowledge.',
      );
      expect(userWritingRequest.aiFeedback, tAiFeedback);
      expect(userWritingRequest.aiScore, 8.5);
    });

    test(
      'should create UserWritingRequest entity with optional null values',
      () {
        // arrange
        const userWritingRequest = UserWritingRequest(
          userId: 123,
          submissionText: 'Another writing submission.',
        );

        // assert
        expect(userWritingRequest.userId, 123);
        expect(userWritingRequest.promptId, isNull);
        expect(
          userWritingRequest.submissionText,
          'Another writing submission.',
        );
        expect(userWritingRequest.aiFeedback, isNull);
        expect(userWritingRequest.aiScore, isNull);
      },
    );

    test('should support equality comparison', () {
      // arrange
      const userWritingRequest1 = UserWritingRequest(
        userId: 123,
        promptId: 456,
        submissionText: 'Test submission',
        aiScore: 8,
      );

      const userWritingRequest2 = UserWritingRequest(
        userId: 123,
        promptId: 456,
        submissionText: 'Test submission',
        aiScore: 8,
      );

      // assert
      expect(userWritingRequest1, userWritingRequest2);
      expect(userWritingRequest1.hashCode, userWritingRequest2.hashCode);
    });

    test('should support copyWith method', () {
      // arrange
      const originalRequest = UserWritingRequest(
        userId: 123,
        submissionText: 'Original submission',
        aiScore: 7,
      );

      // act
      final updatedRequest = originalRequest.copyWith(
        promptId: 789,
        submissionText: 'Updated submission',
        aiScore: 9,
      );

      // assert
      expect(updatedRequest.userId, 123);
      expect(updatedRequest.promptId, 789);
      expect(updatedRequest.submissionText, 'Updated submission');
      expect(updatedRequest.aiScore, 9.0);
    });

    test('should validate required fields', () {
      // This test ensures that userId and submissionText are required
      const request = UserWritingRequest(
        userId: 123,
        submissionText: 'Required submission text',
      );

      expect(request.userId, isNotNull);
      expect(request.submissionText, isNotEmpty);
    });
  });

  group('UserWritingUpdateRequest Entity', () {
    final testEvaluatedAt = DateTime(2024, 1, 18, 10, 15);

    const tAiFeedback = {
      'grammar': 'Excellent',
      'vocabulary': 'Outstanding',
      'coherence': 'Excellent',
    };

    test(
      'should create UserWritingUpdateRequest entity with correct values',
      () {
        // arrange
        final userWritingUpdateRequest = UserWritingUpdateRequest(
          submissionText: 'Updated submission text with improvements.',
          aiFeedback: tAiFeedback,
          aiScore: 9.2,
          evaluatedAt: testEvaluatedAt,
        );

        // assert
        expect(
          userWritingUpdateRequest.submissionText,
          'Updated submission text with improvements.',
        );
        expect(userWritingUpdateRequest.aiFeedback, tAiFeedback);
        expect(userWritingUpdateRequest.aiScore, 9.2);
        expect(userWritingUpdateRequest.evaluatedAt, testEvaluatedAt);
      },
    );

    test(
      'should create UserWritingUpdateRequest entity with all null values',
      () {
        // arrange
        const userWritingUpdateRequest = UserWritingUpdateRequest();

        // assert
        expect(userWritingUpdateRequest.submissionText, isNull);
        expect(userWritingUpdateRequest.aiFeedback, isNull);
        expect(userWritingUpdateRequest.aiScore, isNull);
        expect(userWritingUpdateRequest.evaluatedAt, isNull);
      },
    );

    test(
      'should create UserWritingUpdateRequest entity with partial values',
      () {
        // arrange
        const userWritingUpdateRequest = UserWritingUpdateRequest(
          submissionText: 'Only updating the text',
          aiScore: 7.5,
        );

        // assert
        expect(
          userWritingUpdateRequest.submissionText,
          'Only updating the text',
        );
        expect(userWritingUpdateRequest.aiFeedback, isNull);
        expect(userWritingUpdateRequest.aiScore, 7.5);
        expect(userWritingUpdateRequest.evaluatedAt, isNull);
      },
    );

    test('should support equality comparison', () {
      // arrange
      final userWritingUpdateRequest1 = UserWritingUpdateRequest(
        submissionText: 'Test update',
        aiScore: 8,
        evaluatedAt: testEvaluatedAt,
      );

      final userWritingUpdateRequest2 = UserWritingUpdateRequest(
        submissionText: 'Test update',
        aiScore: 8,
        evaluatedAt: testEvaluatedAt,
      );

      // assert
      expect(userWritingUpdateRequest1, userWritingUpdateRequest2);
      expect(
        userWritingUpdateRequest1.hashCode,
        userWritingUpdateRequest2.hashCode,
      );
    });

    test('should support copyWith method', () {
      // arrange
      const originalRequest = UserWritingUpdateRequest(
        submissionText: 'Original update',
        aiScore: 7,
      );

      // act
      final updatedRequest = originalRequest.copyWith(
        submissionText: 'Modified update',
        aiFeedback: tAiFeedback,
        evaluatedAt: testEvaluatedAt,
      );

      // assert
      expect(updatedRequest.submissionText, 'Modified update');
      expect(updatedRequest.aiFeedback, tAiFeedback);
      expect(updatedRequest.aiScore, 7.0); // Should remain unchanged
      expect(updatedRequest.evaluatedAt, testEvaluatedAt);
    });

    test('should handle AI feedback update scenarios', () {
      // arrange
      const initialFeedback = {'grammar': 'Good'};
      const updatedFeedback = {
        'grammar': 'Excellent',
        'vocabulary': 'Very good',
        'coherence': 'Good',
      };

      const request1 = UserWritingUpdateRequest(
        aiFeedback: initialFeedback,
        aiScore: 7,
      );

      final request2 = request1.copyWith(
        aiFeedback: updatedFeedback,
        aiScore: 8.5,
      );

      // assert
      expect(request1.aiFeedback, initialFeedback);
      expect(request2.aiFeedback, updatedFeedback);
      expect(request1.aiScore, 7.0);
      expect(request2.aiScore, 8.5);
    });

    test('should handle evaluation timestamp updates', () {
      // arrange
      final initialTime = DateTime(2024, 1, 17, 10);
      final updatedTime = DateTime(2024, 1, 17, 15, 30);

      final request1 = UserWritingUpdateRequest(
        evaluatedAt: initialTime,
      );

      final request2 = request1.copyWith(
        evaluatedAt: updatedTime,
      );

      // assert
      expect(request1.evaluatedAt, initialTime);
      expect(request2.evaluatedAt, updatedTime);
    });

    test('should allow clearing values with null', () {
      // arrange
      final requestWithValues = UserWritingUpdateRequest(
        submissionText: 'Some text',
        aiFeedback: tAiFeedback,
        aiScore: 8,
        evaluatedAt: testEvaluatedAt,
      );

      // act
      final clearedRequest = requestWithValues.copyWith(
        aiFeedback: null,
        aiScore: null,
      );

      // assert
      expect(clearedRequest.submissionText, 'Some text');
      expect(clearedRequest.aiFeedback, isNull);
      expect(clearedRequest.aiScore, isNull);
      expect(clearedRequest.evaluatedAt, testEvaluatedAt);
    });
  });
}
