import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/writing/domain/entities/writing_prompt.dart';

void main() {
  group('WritingPrompt Entity', () {
    final testDateTime = DateTime(2024, 1, 15, 10, 30);

    test('should create WritingPrompt entity with correct values', () {
      // arrange
      final writingPrompt = WritingPrompt(
        id: 1,
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      // assert
      expect(writingPrompt.id, 1);
      expect(writingPrompt.userId, 123);
      expect(
        writingPrompt.promptText,
        'Describe your favorite hobby and explain why you enjoy it.',
      );
      expect(writingPrompt.topic, 'Personal Experience');
      expect(writingPrompt.difficultyLevel, 'Intermediate');
      expect(writingPrompt.createdAt, testDateTime);
    });

    test('should create WritingPrompt entity with optional null values', () {
      // arrange
      final writingPrompt = WritingPrompt(
        id: 2,
        promptText: 'What is your opinion about climate change?',
        createdAt: testDateTime,
      );

      // assert
      expect(writingPrompt.id, 2);
      expect(writingPrompt.userId, isNull);
      expect(
        writingPrompt.promptText,
        'What is your opinion about climate change?',
      );
      expect(writingPrompt.topic, isNull);
      expect(writingPrompt.difficultyLevel, isNull);
      expect(writingPrompt.createdAt, testDateTime);
    });

    test('should support equality comparison', () {
      // arrange
      final writingPrompt1 = WritingPrompt(
        id: 1,
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      final writingPrompt2 = WritingPrompt(
        id: 1,
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      // assert
      expect(writingPrompt1, writingPrompt2);
      expect(writingPrompt1.hashCode, writingPrompt2.hashCode);
    });

    test('should not be equal when properties differ', () {
      // arrange
      final writingPrompt1 = WritingPrompt(
        id: 1,
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      final writingPrompt2 = WritingPrompt(
        id: 2,
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      // assert
      expect(writingPrompt1, isNot(writingPrompt2));
      expect(writingPrompt1.hashCode, isNot(writingPrompt2.hashCode));
    });

    test('should support copyWith method', () {
      // arrange
      final originalPrompt = WritingPrompt(
        id: 1,
        userId: 123,
        promptText: 'Original prompt',
        topic: 'Original Topic',
        difficultyLevel: 'Beginner',
        createdAt: testDateTime,
      );

      // act
      final updatedPrompt = originalPrompt.copyWith(
        promptText: 'Updated prompt',
        difficultyLevel: 'Advanced',
      );

      // assert
      expect(updatedPrompt.id, 1);
      expect(updatedPrompt.userId, 123);
      expect(updatedPrompt.promptText, 'Updated prompt');
      expect(updatedPrompt.topic, 'Original Topic');
      expect(updatedPrompt.difficultyLevel, 'Advanced');
      expect(updatedPrompt.createdAt, testDateTime);
    });

    test('should handle toString method', () {
      // arrange
      final writingPrompt = WritingPrompt(
        id: 1,
        userId: 123,
        promptText: 'Test prompt',
        topic: 'Test Topic',
        difficultyLevel: 'Intermediate',
        createdAt: testDateTime,
      );

      // act
      final stringRepresentation = writingPrompt.toString();

      // assert
      expect(stringRepresentation, contains('WritingPrompt'));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('Test prompt'));
    });
  });

  group('WritingPromptRequest Entity', () {
    test('should create WritingPromptRequest entity with correct values', () {
      // arrange
      const writingPromptRequest = WritingPromptRequest(
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
      );

      // assert
      expect(writingPromptRequest.userId, 123);
      expect(
        writingPromptRequest.promptText,
        'Describe your favorite hobby and explain why you enjoy it.',
      );
      expect(writingPromptRequest.topic, 'Personal Experience');
      expect(writingPromptRequest.difficultyLevel, 'Intermediate');
    });

    test(
      'should create WritingPromptRequest entity with optional null values',
      () {
        // arrange
        const writingPromptRequest = WritingPromptRequest(
          promptText: 'What is your opinion about climate change?',
        );

        // assert
        expect(writingPromptRequest.userId, isNull);
        expect(
          writingPromptRequest.promptText,
          'What is your opinion about climate change?',
        );
        expect(writingPromptRequest.topic, isNull);
        expect(writingPromptRequest.difficultyLevel, isNull);
      },
    );

    test('should support equality comparison', () {
      // arrange
      const writingPromptRequest1 = WritingPromptRequest(
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
      );

      const writingPromptRequest2 = WritingPromptRequest(
        userId: 123,
        promptText:
            'Describe your favorite hobby and explain why you enjoy it.',
        topic: 'Personal Experience',
        difficultyLevel: 'Intermediate',
      );

      // assert
      expect(writingPromptRequest1, writingPromptRequest2);
      expect(writingPromptRequest1.hashCode, writingPromptRequest2.hashCode);
    });

    test('should support copyWith method', () {
      // arrange
      const originalRequest = WritingPromptRequest(
        userId: 123,
        promptText: 'Original prompt',
        topic: 'Original Topic',
        difficultyLevel: 'Beginner',
      );

      // act
      final updatedRequest = originalRequest.copyWith(
        promptText: 'Updated prompt',
        difficultyLevel: 'Advanced',
      );

      // assert
      expect(updatedRequest.userId, 123);
      expect(updatedRequest.promptText, 'Updated prompt');
      expect(updatedRequest.topic, 'Original Topic');
      expect(updatedRequest.difficultyLevel, 'Advanced');
    });

    test('should validate required promptText field', () {
      // This test ensures that promptText is required by the entity structure
      // If someone tries to create a WritingPromptRequest without promptText,
      // it should fail at compile time due to the required keyword
      const request = WritingPromptRequest(
        promptText: 'Required prompt text',
      );

      expect(request.promptText, isNotEmpty);
    });

    test('should handle different difficulty levels', () {
      // arrange & act
      const beginnerRequest = WritingPromptRequest(
        promptText: 'Simple prompt',
        difficultyLevel: 'Beginner',
      );

      const intermediateRequest = WritingPromptRequest(
        promptText: 'Moderate prompt',
        difficultyLevel: 'Intermediate',
      );

      const advancedRequest = WritingPromptRequest(
        promptText: 'Complex prompt',
        difficultyLevel: 'Advanced',
      );

      // assert
      expect(beginnerRequest.difficultyLevel, 'Beginner');
      expect(intermediateRequest.difficultyLevel, 'Intermediate');
      expect(advancedRequest.difficultyLevel, 'Advanced');
    });

    test('should handle different topics', () {
      // arrange & act
      const personalRequest = WritingPromptRequest(
        promptText: 'Personal experience prompt',
        topic: 'Personal Experience',
      );

      const academicRequest = WritingPromptRequest(
        promptText: 'Academic discussion prompt',
        topic: 'Academic',
      );

      const businessRequest = WritingPromptRequest(
        promptText: 'Business context prompt',
        topic: 'Business',
      );

      // assert
      expect(personalRequest.topic, 'Personal Experience');
      expect(academicRequest.topic, 'Academic');
      expect(businessRequest.topic, 'Business');
    });
  });
}
