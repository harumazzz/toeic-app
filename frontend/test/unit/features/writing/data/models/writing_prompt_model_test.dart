import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/writing/data/models/writing_prompt_model.dart';
import 'package:learn/features/writing/domain/entities/writing_prompt.dart';

void main() {
  group('WritingPromptModel', () {
    final testDateTime = DateTime(2024, 1, 15, 10, 30);

    final tWritingPromptModel = WritingPromptModel(
      id: 1,
      userId: 123,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
      createdAt: testDateTime,
    );

    final tWritingPrompt = WritingPrompt(
      id: 1,
      userId: 123,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
      createdAt: testDateTime,
    );

    test('should be a subclass of WritingPrompt entity', () async {
      // assert
      expect(tWritingPromptModel.toEntity(), isA<WritingPrompt>());
    });

    test('should convert from JSON correctly with all fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'user_id': 123,
        'prompt_text':
            'Describe your favorite hobby and explain why you enjoy it.',
        'topic': 'Personal Experience',
        'difficulty_level': 'Intermediate',
        'created_at': testDateTime.toIso8601String(),
      };

      // act
      final result = WritingPromptModel.fromJson(jsonMap);

      // assert
      expect(result, tWritingPromptModel);
    });

    test(
      'should convert from JSON correctly with optional null fields',
      () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': 2,
          'user_id': null,
          'prompt_text': 'What is your opinion about climate change?',
          'topic': null,
          'difficulty_level': null,
          'created_at': testDateTime.toIso8601String(),
        };

        final expectedModel = WritingPromptModel(
          id: 2,
          promptText: 'What is your opinion about climate change?',
          createdAt: testDateTime,
        );

        // act
        final result = WritingPromptModel.fromJson(jsonMap);

        // assert
        expect(result, expectedModel);
        expect(result.userId, isNull);
        expect(result.topic, isNull);
        expect(result.difficultyLevel, isNull);
      },
    );

    test('should convert to JSON correctly with all fields', () async {
      // arrange
      final expectedJson = {
        'id': 1,
        'user_id': 123,
        'prompt_text':
            'Describe your favorite hobby and explain why you enjoy it.',
        'topic': 'Personal Experience',
        'difficulty_level': 'Intermediate',
        'created_at': testDateTime.toIso8601String(),
      };

      // act
      final result = tWritingPromptModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test(
      'should convert to JSON correctly with optional null fields',
      () async {
        // arrange
        final modelWithNulls = WritingPromptModel(
          id: 2,
          promptText: 'What is your opinion about climate change?',
          createdAt: testDateTime,
        );

        final expectedJson = {
          'id': 2,
          'user_id': null,
          'prompt_text': 'What is your opinion about climate change?',
          'topic': null,
          'difficulty_level': null,
          'created_at': testDateTime.toIso8601String(),
        };

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result, expectedJson);
      },
    );

    test('should convert to entity correctly', () async {
      // act
      final result = tWritingPromptModel.toEntity();

      // assert
      expect(result, tWritingPrompt);
      expect(result.id, 1);
      expect(result.userId, 123);
      expect(
        result.promptText,
        'Describe your favorite hobby and explain why you enjoy it.',
      );
      expect(result.topic, 'Personal Experience');
      expect(result.difficultyLevel, 'Intermediate');
      expect(result.createdAt, testDateTime);
    });

    test('should convert to entity correctly with null fields', () async {
      // arrange
      final modelWithNulls = WritingPromptModel(
        id: 3,
        promptText: 'Simple prompt',
        createdAt: testDateTime,
      );

      // act
      final result = modelWithNulls.toEntity();

      // assert
      expect(result.id, 3);
      expect(result.userId, isNull);
      expect(result.promptText, 'Simple prompt');
      expect(result.topic, isNull);
      expect(result.difficultyLevel, isNull);
      expect(result.createdAt, testDateTime);
    });

    test('should handle JSON with DateTime string parsing', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'user_id': 123,
        'prompt_text': 'Test prompt',
        'topic': 'Test Topic',
        'difficulty_level': 'Beginner',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      // act
      final result = WritingPromptModel.fromJson(jsonMap);

      // assert
      expect(result.createdAt, isA<DateTime>());
      expect(result.createdAt.year, 2024);
      expect(result.createdAt.month, 1);
      expect(result.createdAt.day, 15);
    });

    test('should maintain data integrity in JSON round trip', () async {
      // arrange
      final originalModel = WritingPromptModel(
        id: 1,
        userId: 123,
        promptText: 'Round trip test prompt',
        topic: 'Testing',
        difficultyLevel: 'Advanced',
        createdAt: testDateTime,
      );

      // act
      final json = originalModel.toJson();
      final reconstructedModel = WritingPromptModel.fromJson(json);

      // assert
      expect(reconstructedModel, originalModel);
      expect(reconstructedModel.id, originalModel.id);
      expect(reconstructedModel.userId, originalModel.userId);
      expect(reconstructedModel.promptText, originalModel.promptText);
      expect(reconstructedModel.topic, originalModel.topic);
      expect(reconstructedModel.difficultyLevel, originalModel.difficultyLevel);
      expect(reconstructedModel.createdAt, originalModel.createdAt);
    });

    test('should handle different difficulty levels in JSON', () async {
      // arrange
      final beginnerJson = {
        'id': 1,
        'prompt_text': 'Simple prompt',
        'difficulty_level': 'Beginner',
        'created_at': testDateTime.toIso8601String(),
      };

      final intermediateJson = {
        'id': 2,
        'prompt_text': 'Moderate prompt',
        'difficulty_level': 'Intermediate',
        'created_at': testDateTime.toIso8601String(),
      };

      final advancedJson = {
        'id': 3,
        'prompt_text': 'Complex prompt',
        'difficulty_level': 'Advanced',
        'created_at': testDateTime.toIso8601String(),
      };

      // act
      final beginnerModel = WritingPromptModel.fromJson(beginnerJson);
      final intermediateModel = WritingPromptModel.fromJson(intermediateJson);
      final advancedModel = WritingPromptModel.fromJson(advancedJson);

      // assert
      expect(beginnerModel.difficultyLevel, 'Beginner');
      expect(intermediateModel.difficultyLevel, 'Intermediate');
      expect(advancedModel.difficultyLevel, 'Advanced');
    });

    test('should handle different topics in JSON', () async {
      // arrange
      final personalJson = {
        'id': 1,
        'prompt_text': 'Personal prompt',
        'topic': 'Personal Experience',
        'created_at': testDateTime.toIso8601String(),
      };

      final academicJson = {
        'id': 2,
        'prompt_text': 'Academic prompt',
        'topic': 'Academic',
        'created_at': testDateTime.toIso8601String(),
      };

      final businessJson = {
        'id': 3,
        'prompt_text': 'Business prompt',
        'topic': 'Business',
        'created_at': testDateTime.toIso8601String(),
      };

      // act
      final personalModel = WritingPromptModel.fromJson(personalJson);
      final academicModel = WritingPromptModel.fromJson(academicJson);
      final businessModel = WritingPromptModel.fromJson(businessJson);

      // assert
      expect(personalModel.topic, 'Personal Experience');
      expect(academicModel.topic, 'Academic');
      expect(businessModel.topic, 'Business');
    });
  });

  group('WritingPromptRequestModel', () {
    const tWritingPromptRequestModel = WritingPromptRequestModel(
      userId: 123,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
    );

    const tWritingPromptRequest = WritingPromptRequest(
      userId: 123,
      promptText: 'Describe your favorite hobby and explain why you enjoy it.',
      topic: 'Personal Experience',
      difficultyLevel: 'Intermediate',
    );

    test('should convert from JSON correctly with all fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'user_id': 123,
        'prompt_text':
            'Describe your favorite hobby and explain why you enjoy it.',
        'topic': 'Personal Experience',
        'difficulty_level': 'Intermediate',
      };

      // act
      final result = WritingPromptRequestModel.fromJson(jsonMap);

      // assert
      expect(result, tWritingPromptRequestModel);
    });

    test(
      'should convert from JSON correctly with optional null fields',
      () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'user_id': null,
          'prompt_text': 'What is your opinion about climate change?',
          'topic': null,
          'difficulty_level': null,
        };

        const expectedModel = WritingPromptRequestModel(
          promptText: 'What is your opinion about climate change?',
        );

        // act
        final result = WritingPromptRequestModel.fromJson(jsonMap);

        // assert
        expect(result, expectedModel);
        expect(result.userId, isNull);
        expect(result.topic, isNull);
        expect(result.difficultyLevel, isNull);
      },
    );

    test('should convert to JSON correctly with all fields', () async {
      // arrange
      final expectedJson = {
        'user_id': 123,
        'prompt_text':
            'Describe your favorite hobby and explain why you enjoy it.',
        'topic': 'Personal Experience',
        'difficulty_level': 'Intermediate',
      };

      // act
      final result = tWritingPromptRequestModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test(
      'should convert to JSON correctly with optional null fields',
      () async {
        // arrange
        const modelWithNulls = WritingPromptRequestModel(
          promptText: 'What is your opinion about climate change?',
        );

        final expectedJson = {
          'user_id': null,
          'prompt_text': 'What is your opinion about climate change?',
          'topic': null,
          'difficulty_level': null,
        };

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result, expectedJson);
      },
    );

    test('should create from entity correctly', () async {
      // act
      final result = tWritingPromptRequest.toModel();

      // assert
      expect(result, tWritingPromptRequestModel);
      expect(result.userId, 123);
      expect(
        result.promptText,
        'Describe your favorite hobby and explain why you enjoy it.',
      );
      expect(result.topic, 'Personal Experience');
      expect(result.difficultyLevel, 'Intermediate');
    });

    test('should create from entity correctly with null fields', () async {
      // arrange
      const entityWithNulls = WritingPromptRequest(
        promptText: 'Simple prompt',
      );

      // act
      final result = entityWithNulls.toModel();

      // assert
      expect(result.userId, isNull);
      expect(result.promptText, 'Simple prompt');
      expect(result.topic, isNull);
      expect(result.difficultyLevel, isNull);
    });

    test('should maintain data integrity in JSON round trip', () async {
      // arrange
      const originalModel = WritingPromptRequestModel(
        userId: 456,
        promptText: 'Round trip test request',
        topic: 'Testing',
        difficultyLevel: 'Advanced',
      );

      // act
      final json = originalModel.toJson();
      final reconstructedModel = WritingPromptRequestModel.fromJson(json);

      // assert
      expect(reconstructedModel, originalModel);
      expect(reconstructedModel.userId, originalModel.userId);
      expect(reconstructedModel.promptText, originalModel.promptText);
      expect(reconstructedModel.topic, originalModel.topic);
      expect(reconstructedModel.difficultyLevel, originalModel.difficultyLevel);
    });

    test('should handle entity to model to JSON conversion', () async {
      // arrange
      const entity = WritingPromptRequest(
        userId: 789,
        promptText: 'Entity to model test',
        topic: 'Conversion',
        difficultyLevel: 'Intermediate',
      );

      final expectedJson = {
        'user_id': 789,
        'prompt_text': 'Entity to model test',
        'topic': 'Conversion',
        'difficulty_level': 'Intermediate',
      };

      // act
      final model = entity.toModel();
      final json = model.toJson();

      // assert
      expect(json, expectedJson);
    });

    test('should handle JSON to model to entity conversion', () async {
      // arrange
      final json = {
        'user_id': 321,
        'prompt_text': 'JSON to entity test',
        'topic': 'Testing',
        'difficulty_level': 'Advanced',
      };

      const expectedEntity = WritingPromptRequest(
        userId: 321,
        promptText: 'JSON to entity test',
        topic: 'Testing',
        difficultyLevel: 'Advanced',
      );

      // act
      final model = WritingPromptRequestModel.fromJson(json);
      // Note: We can't directly convert to entity from request model,
      // but we can verify the model has the correct values

      // assert
      expect(model.userId, expectedEntity.userId);
      expect(model.promptText, expectedEntity.promptText);
      expect(model.topic, expectedEntity.topic);
      expect(model.difficultyLevel, expectedEntity.difficultyLevel);
    });

    test('should handle edge cases with empty strings', () async {
      // arrange
      final jsonWithEmptyStrings = {
        'user_id': 123,
        'prompt_text': '',
        'topic': '',
        'difficulty_level': '',
      };

      // act
      final result = WritingPromptRequestModel.fromJson(jsonWithEmptyStrings);

      // assert
      expect(result.userId, 123);
      expect(result.promptText, '');
      expect(result.topic, '');
      expect(result.difficultyLevel, '');
    });
  });
}
