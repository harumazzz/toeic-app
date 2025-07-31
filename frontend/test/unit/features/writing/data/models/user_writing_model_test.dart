// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/writing/data/models/user_writing_model.dart';
import 'package:learn/features/writing/domain/entities/user_writing.dart';
import 'package:learn/features/writing/domain/entities/writing_feedback.dart';

void main() {
  group('UserWritingModel', () {
    final testSubmittedAt = DateTime(2024, 1, 17, 16, 45);
    final testEvaluatedAt = DateTime(2024, 1, 17, 16, 50);
    final testUpdatedAt = DateTime(2024, 1, 17, 16, 50);

    const tAiFeedback = WritingFeedback(
      overallScore: 8,
      feedback: 'Good writing with room for improvement',
      grammarScore: 7,
      grammarFeedback: 'Good',
      vocabularyScore: 9,
      vocabularyFeedback: 'Excellent',
      organizationScore: 8,
      organizationFeedback: 'Very good',
      suggestions: [
        'Consider using more transition words',
        'Expand on your main points',
      ],
    );

    final tUserWritingModel = UserWritingModel(
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

    test('should be a subclass of UserWriting entity', () async {
      // assert
      expect(tUserWritingModel.toEntity(), isA<UserWriting>());
    });

    test('should convert from JSON correctly with all fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'user_id': 123,
        'prompt_id': 456,
        'submission_text':
            'My favorite hobby is reading because it expands my knowledge and vocabulary.',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.5,
        'submitted_at': testSubmittedAt.toIso8601String(),
        'evaluated_at': testEvaluatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      // act
      final result = UserWritingModel.fromJson(jsonMap);

      // assert
      expect(result, tUserWritingModel);
    });

    test(
      'should convert from JSON correctly with optional null fields',
      () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': 2,
          'user_id': 123,
          'prompt_id': null,
          'submission_text': 'Another writing submission.',
          'ai_feedback': null,
          'ai_score': null,
          'submitted_at': testSubmittedAt.toIso8601String(),
          'evaluated_at': null,
          'updated_at': testUpdatedAt.toIso8601String(),
        };

        final expectedModel = UserWritingModel(
          id: 2,
          userId: 123,
          submissionText: 'Another writing submission.',
          submittedAt: testSubmittedAt,
          updatedAt: testUpdatedAt,
        );

        // act
        final result = UserWritingModel.fromJson(jsonMap);

        // assert
        expect(result, expectedModel);
        expect(result.promptId, isNull);
        expect(result.aiFeedback, isNull);
        expect(result.aiScore, isNull);
        expect(result.evaluatedAt, isNull);
      },
    );

    test('should convert to JSON correctly with all fields', () async {
      // arrange
      final expectedJson = {
        'id': 1,
        'user_id': 123,
        'prompt_id': 456,
        'submission_text':
            'My favorite hobby is reading because it expands my knowledge and vocabulary.',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.5,
        'submitted_at': testSubmittedAt.toIso8601String(),
        'evaluated_at': testEvaluatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      // act
      final result = tUserWritingModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test(
      'should convert to JSON correctly with optional null fields',
      () async {
        // arrange
        final modelWithNulls = UserWritingModel(
          id: 3,
          userId: 123,
          submissionText: 'Simple submission',
          submittedAt: testSubmittedAt,
          updatedAt: testUpdatedAt,
        );

        final expectedJson = {
          'id': 3,
          'user_id': 123,
          'prompt_id': null,
          'submission_text': 'Simple submission',
          'ai_feedback': null,
          'ai_score': null,
          'submitted_at': testSubmittedAt.toIso8601String(),
          'evaluated_at': null,
          'updated_at': testUpdatedAt.toIso8601String(),
        };

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result, expectedJson);
      },
    );

    test('should convert to entity correctly', () async {
      // act
      final result = tUserWritingModel.toEntity();

      // assert
      expect(result, tUserWriting);
      expect(result.id, 1);
      expect(result.userId, 123);
      expect(result.promptId, 456);
      expect(
        result.submissionText,
        'My favorite hobby is reading because it expands my knowledge and vocabulary.',
      );
      expect(result.aiFeedback, tAiFeedback);
      expect(result.aiScore, 8.5);
      expect(result.submittedAt, testSubmittedAt);
      expect(result.evaluatedAt, testEvaluatedAt);
      expect(result.updatedAt, testUpdatedAt);
    });

    test('should convert to entity correctly with null fields', () async {
      // arrange
      final modelWithNulls = UserWritingModel(
        id: 4,
        userId: 123,
        submissionText: 'Simple submission',
        submittedAt: testSubmittedAt,
        updatedAt: testUpdatedAt,
      );

      // act
      final result = modelWithNulls.toEntity();

      // assert
      expect(result.id, 4);
      expect(result.userId, 123);
      expect(result.promptId, isNull);
      expect(result.submissionText, 'Simple submission');
      expect(result.aiFeedback, isNull);
      expect(result.aiScore, isNull);
      expect(result.submittedAt, testSubmittedAt);
      expect(result.evaluatedAt, isNull);
      expect(result.updatedAt, testUpdatedAt);
    });

    test('should handle JSON with DateTime string parsing', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'user_id': 123,
        'submission_text': 'Test submission',
        'submitted_at': '2024-01-17T16:45:00.000Z',
        'evaluated_at': '2024-01-17T16:50:00.000Z',
        'updated_at': '2024-01-17T16:50:00.000Z',
      };

      // act
      final result = UserWritingModel.fromJson(jsonMap);

      // assert
      expect(result.submittedAt, isA<DateTime>());
      expect(result.evaluatedAt, isA<DateTime>());
      expect(result.updatedAt, isA<DateTime>());
    });

    test('should maintain data integrity in JSON round trip', () async {
      // arrange
      final originalModel = UserWritingModel(
        id: 1,
        userId: 123,
        promptId: 456,
        submissionText: 'Round trip test submission',
        aiFeedback: tAiFeedback,
        aiScore: 8.5,
        submittedAt: testSubmittedAt,
        evaluatedAt: testEvaluatedAt,
        updatedAt: testUpdatedAt,
      );

      // act
      final json = originalModel.toJson();
      final reconstructedModel = UserWritingModel.fromJson(json);

      // assert
      expect(reconstructedModel, originalModel);
      expect(reconstructedModel.id, originalModel.id);
      expect(reconstructedModel.userId, originalModel.userId);
      expect(reconstructedModel.promptId, originalModel.promptId);
      expect(reconstructedModel.submissionText, originalModel.submissionText);
      expect(reconstructedModel.aiFeedback, originalModel.aiFeedback);
      expect(reconstructedModel.aiScore, originalModel.aiScore);
      expect(reconstructedModel.submittedAt, originalModel.submittedAt);
      expect(reconstructedModel.evaluatedAt, originalModel.evaluatedAt);
      expect(reconstructedModel.updatedAt, originalModel.updatedAt);
    });

    test('should handle complex AI feedback structure in JSON', () async {
      // arrange
      const complexFeedbackJson = {
        'overall_score': 8,
        'feedback': 'Strong writing with good structure and ideas',
        'grammar_score': 8,
        'grammar_feedback': 'Good use of grammar with minor issues',
        'vocabulary_score': 9,
        'vocabulary_feedback': 'Good range of vocabulary',
        'organization_score': 8,
        'organization_feedback': 'Well-organized structure',
        'suggestions': [
          'Review past perfect usage',
          'Use more varied synonyms',
        ],
        'strengths': [
          'Good use of topic-specific terms',
          'Clear paragraph structure',
        ],
        'areas_for_improvement': ['Tense consistency', 'Vocabulary range'],
      };

      const expectedFeedback = WritingFeedback(
        overallScore: 8,
        feedback: 'Strong writing with good structure and ideas',
        grammarScore: 8,
        grammarFeedback: 'Good use of grammar with minor issues',
        vocabularyScore: 9,
        vocabularyFeedback: 'Good range of vocabulary',
        organizationScore: 8,
        organizationFeedback: 'Well-organized structure',
        suggestions: ['Review past perfect usage', 'Use more varied synonyms'],
        strengths: [
          'Good use of topic-specific terms',
          'Clear paragraph structure',
        ],
        areasForImprovement: ['Tense consistency', 'Vocabulary range'],
      );

      final jsonMap = {
        'id': 1,
        'user_id': 123,
        'submission_text': 'Complex AI feedback test',
        'ai_feedback': complexFeedbackJson,
        'ai_score': 8.5,
        'submitted_at': testSubmittedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      // act
      final result = UserWritingModel.fromJson(jsonMap);

      // assert
      expect(result.aiFeedback, expectedFeedback);
      expect(result.aiFeedback!.grammarScore, 8);
      expect(result.aiFeedback!.suggestions, isA<List<String>>());
      expect(result.aiFeedback!.strengths, isA<List<String>>());
    });

    test('should handle different AI score ranges in JSON', () async {
      // arrange
      final lowScoreJson = {
        'id': 1,
        'user_id': 123,
        'submission_text': 'Low score submission',
        'ai_score': 2.5,
        'submitted_at': testSubmittedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final highScoreJson = {
        'id': 2,
        'user_id': 123,
        'submission_text': 'High score submission',
        'ai_score': 9.8,
        'submitted_at': testSubmittedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      // act
      final lowScoreModel = UserWritingModel.fromJson(lowScoreJson);
      final highScoreModel = UserWritingModel.fromJson(highScoreJson);

      // assert
      expect(lowScoreModel.aiScore, 2.5);
      expect(highScoreModel.aiScore, 9.8);
    });
  });

  group('UserWritingRequestModel', () {
    const tAiFeedback = WritingFeedback(
      overallScore: 8,
      feedback: 'Good writing overall',
      grammarScore: 7,
      grammarFeedback: 'Good',
      vocabularyScore: 9,
      vocabularyFeedback: 'Excellent',
      organizationScore: 8,
      organizationFeedback: 'Very good',
    );

    const tUserWritingRequestModel = UserWritingRequestModel(
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge.',
      aiFeedback: tAiFeedback,
      aiScore: 8.5,
    );

    const tUserWritingRequest = UserWritingRequest(
      userId: 123,
      promptId: 456,
      submissionText:
          'My favorite hobby is reading because it expands my knowledge.',
      aiFeedback: tAiFeedback,
      aiScore: 8.5,
    );

    test('should convert from JSON correctly with all fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'user_id': 123,
        'prompt_id': 456,
        'submission_text':
            'My favorite hobby is reading because it expands my knowledge.',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.5,
      };

      // act
      final result = UserWritingRequestModel.fromJson(jsonMap);

      // assert
      expect(result, tUserWritingRequestModel);
    });

    test(
      'should convert from JSON correctly with optional null fields',
      () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'user_id': 123,
          'prompt_id': null,
          'submission_text': 'Simple submission without feedback',
          'ai_feedback': null,
          'ai_score': null,
        };

        const expectedModel = UserWritingRequestModel(
          userId: 123,
          submissionText: 'Simple submission without feedback',
        );

        // act
        final result = UserWritingRequestModel.fromJson(jsonMap);

        // assert
        expect(result, expectedModel);
        expect(result.promptId, isNull);
        expect(result.aiFeedback, isNull);
        expect(result.aiScore, isNull);
      },
    );

    test('should convert to JSON correctly with all fields', () async {
      // arrange
      final expectedJson = {
        'user_id': 123,
        'prompt_id': 456,
        'submission_text':
            'My favorite hobby is reading because it expands my knowledge.',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.5,
      };

      // act
      final result = tUserWritingRequestModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test(
      'should convert to JSON correctly with optional null fields',
      () async {
        // arrange
        const modelWithNulls = UserWritingRequestModel(
          userId: 123,
          submissionText: 'Simple submission without feedback',
        );

        final expectedJson = {
          'user_id': 123,
          'prompt_id': null,
          'submission_text': 'Simple submission without feedback',
          'ai_feedback': null,
          'ai_score': null,
        };

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result, expectedJson);
      },
    );

    test('should create from entity correctly', () async {
      // act
      final result = tUserWritingRequest.toModel();

      // assert
      expect(result, tUserWritingRequestModel);
      expect(result.userId, 123);
      expect(result.promptId, 456);
      expect(
        result.submissionText,
        'My favorite hobby is reading because it expands my knowledge.',
      );
      expect(result.aiFeedback, tAiFeedback);
      expect(result.aiScore, 8.5);
    });

    test('should create from entity correctly with null fields', () async {
      // arrange
      const entityWithNulls = UserWritingRequest(
        userId: 123,
        submissionText: 'Simple submission',
      );

      // act
      final result = entityWithNulls.toModel();

      // assert
      expect(result.userId, 123);
      expect(result.promptId, isNull);
      expect(result.submissionText, 'Simple submission');
      expect(result.aiFeedback, isNull);
      expect(result.aiScore, isNull);
    });

    test('should maintain data integrity in JSON round trip', () async {
      // arrange
      const originalModel = UserWritingRequestModel(
        userId: 456,
        promptId: 789,
        submissionText: 'Round trip test request',
        aiFeedback: tAiFeedback,
        aiScore: 7.5,
      );

      // act
      final json = originalModel.toJson();
      final reconstructedModel = UserWritingRequestModel.fromJson(json);

      // assert
      expect(reconstructedModel, originalModel);
      expect(reconstructedModel.userId, originalModel.userId);
      expect(reconstructedModel.promptId, originalModel.promptId);
      expect(reconstructedModel.submissionText, originalModel.submissionText);
      expect(reconstructedModel.aiFeedback, originalModel.aiFeedback);
      expect(reconstructedModel.aiScore, originalModel.aiScore);
    });

    test('should handle entity to model to JSON conversion', () async {
      // arrange
      const entity = UserWritingRequest(
        userId: 789,
        promptId: 321,
        submissionText: 'Entity to model test',
        aiFeedback: tAiFeedback,
        aiScore: 8,
      );

      final expectedJson = {
        'user_id': 789,
        'prompt_id': 321,
        'submission_text': 'Entity to model test',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.0,
      };

      // act
      final model = entity.toModel();
      final json = model.toJson();

      // assert
      expect(json, expectedJson);
    });

    test('should handle complex AI feedback in JSON conversion', () async {
      // arrange
      const complexFeedbackJson = {
        'overall_score': 8,
        'feedback': 'Good overall structure',
        'grammar_score': 8,
        'grammar_feedback': 'Good overall structure',
        'vocabulary_score': 9,
        'vocabulary_feedback': 'Academic vocabulary, Varied word choice',
        'suggestions': ['Use more advanced synonyms'],
        'strengths': ['Academic vocabulary', 'Varied word choice'],
      };

      const expectedFeedback = WritingFeedback(
        overallScore: 8,
        feedback: 'Good overall structure',
        grammarScore: 8,
        grammarFeedback: 'Good overall structure',
        vocabularyScore: 9,
        vocabularyFeedback: 'Academic vocabulary, Varied word choice',
        suggestions: ['Use more advanced synonyms'],
        strengths: ['Academic vocabulary', 'Varied word choice'],
      );

      final jsonWithComplexFeedback = {
        'user_id': 123,
        'submission_text': 'Complex feedback test',
        'ai_feedback': complexFeedbackJson,
        'ai_score': 8.5,
      };

      // act
      final result = UserWritingRequestModel.fromJson(jsonWithComplexFeedback);

      // assert
      expect(result.aiFeedback, expectedFeedback);
      expect(result.aiFeedback!.grammarScore, 8);
      expect(result.aiFeedback!.strengths, isA<List<String>>());
    });

    test('should handle edge cases with empty strings', () async {
      // arrange
      const emptyFeedback = WritingFeedback(
        overallScore: 0,
        feedback: '',
      );

      final jsonWithEmptyStrings = {
        'user_id': 123,
        'prompt_id': 456,
        'submission_text': '',
        'ai_feedback': {
          'overall_score': 0,
          'feedback': '',
        },
        'ai_score': 0.0,
      };

      // act
      final result = UserWritingRequestModel.fromJson(jsonWithEmptyStrings);

      // assert
      expect(result.userId, 123);
      expect(result.promptId, 456);
      expect(result.submissionText, '');
      expect(result.aiFeedback, emptyFeedback);
      expect(result.aiScore, 0.0);
    });
  });

  group('UserWritingUpdateRequestModel', () {
    final testEvaluatedAt = DateTime(2024, 1, 18, 10, 15);

    const tAiFeedback = WritingFeedback(
      overallScore: 9,
      feedback: 'Outstanding writing',
      grammarScore: 9,
      grammarFeedback: 'Excellent',
      vocabularyScore: 9,
      vocabularyFeedback: 'Outstanding',
      organizationScore: 9,
      organizationFeedback: 'Excellent',
    );

    final tUserWritingUpdateRequestModel = UserWritingUpdateRequestModel(
      submissionText: 'Updated submission text with improvements.',
      aiFeedback: tAiFeedback,
      aiScore: 9.2,
      evaluatedAt: testEvaluatedAt,
    );

    final tUserWritingUpdateRequest = UserWritingUpdateRequest(
      submissionText: 'Updated submission text with improvements.',
      aiFeedback: tAiFeedback,
      aiScore: 9.2,
      evaluatedAt: testEvaluatedAt,
    );

    test('should convert from JSON correctly with all fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'submission_text': 'Updated submission text with improvements.',
        'ai_feedback': tAiFeedback,
        'ai_score': 9.2,
        'evaluated_at': testEvaluatedAt.toIso8601String(),
      };

      // act
      final result = UserWritingUpdateRequestModel.fromJson(jsonMap);

      // assert
      expect(result, tUserWritingUpdateRequestModel);
    });

    test('should convert from JSON correctly with all null fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'submission_text': null,
        'ai_feedback': null,
        'ai_score': null,
        'evaluated_at': null,
      };

      const expectedModel = UserWritingUpdateRequestModel();

      // act
      final result = UserWritingUpdateRequestModel.fromJson(jsonMap);

      // assert
      expect(result, expectedModel);
      expect(result.submissionText, isNull);
      expect(result.aiFeedback, isNull);
      expect(result.aiScore, isNull);
      expect(result.evaluatedAt, isNull);
    });

    test('should convert from JSON correctly with partial fields', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'submission_text': 'Only updating the text',
        'ai_score': 7.5,
        'ai_feedback': null,
        'evaluated_at': null,
      };

      const expectedModel = UserWritingUpdateRequestModel(
        submissionText: 'Only updating the text',
        aiScore: 7.5,
      );

      // act
      final result = UserWritingUpdateRequestModel.fromJson(jsonMap);

      // assert
      expect(result, expectedModel);
      expect(result.submissionText, 'Only updating the text');
      expect(result.aiFeedback, isNull);
      expect(result.aiScore, 7.5);
      expect(result.evaluatedAt, isNull);
    });

    test('should convert to JSON correctly with all fields', () async {
      // arrange
      final expectedJson = {
        'submission_text': 'Updated submission text with improvements.',
        'ai_feedback': tAiFeedback,
        'ai_score': 9.2,
        'evaluated_at': testEvaluatedAt.toIso8601String(),
      };

      // act
      final result = tUserWritingUpdateRequestModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test(
      'should convert to JSON correctly with optional null fields',
      () async {
        // arrange
        const modelWithNulls = UserWritingUpdateRequestModel(
          submissionText: 'Only text update',
        );

        final expectedJson = {
          'submission_text': 'Only text update',
          'ai_feedback': null,
          'ai_score': null,
          'evaluated_at': null,
        };

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result, expectedJson);
      },
    );

    test('should create from entity correctly', () async {
      // act
      final result = tUserWritingUpdateRequest.toModel();

      // assert
      expect(result, tUserWritingUpdateRequestModel);
      expect(
        result.submissionText,
        'Updated submission text with improvements.',
      );
      expect(result.aiFeedback, tAiFeedback);
      expect(result.aiScore, 9.2);
      expect(result.evaluatedAt, testEvaluatedAt);
    });

    test('should create from entity correctly with null fields', () async {
      // arrange
      const entityWithNulls = UserWritingUpdateRequest();

      // act
      final result = entityWithNulls.toModel();

      // assert
      expect(result.submissionText, isNull);
      expect(result.aiFeedback, isNull);
      expect(result.aiScore, isNull);
      expect(result.evaluatedAt, isNull);
    });

    test('should maintain data integrity in JSON round trip', () async {
      // arrange
      final originalModel = UserWritingUpdateRequestModel(
        submissionText: 'Round trip test update',
        aiFeedback: tAiFeedback,
        aiScore: 8.5,
        evaluatedAt: testEvaluatedAt,
      );

      // act
      final json = originalModel.toJson();
      final reconstructedModel = UserWritingUpdateRequestModel.fromJson(json);

      // assert
      expect(reconstructedModel, originalModel);
      expect(reconstructedModel.submissionText, originalModel.submissionText);
      expect(reconstructedModel.aiFeedback, originalModel.aiFeedback);
      expect(reconstructedModel.aiScore, originalModel.aiScore);
      expect(reconstructedModel.evaluatedAt, originalModel.evaluatedAt);
    });

    test('should handle entity to model to JSON conversion', () async {
      // arrange
      final entity = UserWritingUpdateRequest(
        submissionText: 'Entity to model test',
        aiFeedback: tAiFeedback,
        aiScore: 8,
        evaluatedAt: testEvaluatedAt,
      );

      final expectedJson = {
        'submission_text': 'Entity to model test',
        'ai_feedback': tAiFeedback,
        'ai_score': 8.0,
        'evaluated_at': testEvaluatedAt.toIso8601String(),
      };

      // act
      final model = entity.toModel();
      final json = model.toJson();

      // assert
      expect(json, expectedJson);
    });

    test('should handle AI feedback update scenarios', () async {
      // arrange
      const initialFeedback = {'grammar': 'Good'};
      const updatedFeedback = {
        'grammar': 'Excellent',
        'vocabulary': 'Very good',
        'coherence': 'Good',
      };

      final jsonWithInitialFeedback = {
        'ai_feedback': initialFeedback,
        'ai_score': 7.0,
      };

      final jsonWithUpdatedFeedback = {
        'ai_feedback': updatedFeedback,
        'ai_score': 8.5,
      };

      // act
      final model1 = UserWritingUpdateRequestModel.fromJson(
        jsonWithInitialFeedback,
      );
      final model2 = UserWritingUpdateRequestModel.fromJson(
        jsonWithUpdatedFeedback,
      );

      // assert
      expect(model1.aiFeedback, initialFeedback);
      expect(model2.aiFeedback, updatedFeedback);
      expect(model1.aiScore, 7.0);
      expect(model2.aiScore, 8.5);
    });

    test('should handle evaluation timestamp updates', () async {
      // arrange
      // ignore: avoid_redundant_argument_values
      final initialTime = DateTime(2024, 1, 17, 10, 0);
      final updatedTime = DateTime(2024, 1, 17, 15, 30);

      final jsonWithInitialTime = {
        'evaluated_at': initialTime.toIso8601String(),
      };

      final jsonWithUpdatedTime = {
        'evaluated_at': updatedTime.toIso8601String(),
      };

      // act
      final model1 = UserWritingUpdateRequestModel.fromJson(
        jsonWithInitialTime,
      );
      final model2 = UserWritingUpdateRequestModel.fromJson(
        jsonWithUpdatedTime,
      );

      // assert
      expect(model1.evaluatedAt, initialTime);
      expect(model2.evaluatedAt, updatedTime);
    });

    test('should handle DateTime string parsing in JSON', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'submission_text': 'DateTime test',
        'evaluated_at': '2024-01-18T10:15:00.000Z',
      };

      // act
      final result = UserWritingUpdateRequestModel.fromJson(jsonMap);

      // assert
      expect(result.evaluatedAt, isA<DateTime>());
      expect(result.evaluatedAt!.year, 2024);
      expect(result.evaluatedAt!.month, 1);
      expect(result.evaluatedAt!.day, 18);
    });

    test('should handle edge cases with empty values', () async {
      // arrange
      const emptyFeedback = WritingFeedback(
        overallScore: 0,
        feedback: '',
      );

      final jsonWithEmptyValues = {
        'submission_text': '',
        'ai_feedback': {
          'overall_score': 0,
          'feedback': '',
        },
        'ai_score': 0.0,
      };

      // act
      final result = UserWritingUpdateRequestModel.fromJson(
        jsonWithEmptyValues,
      );

      // assert
      expect(result.submissionText, '');
      expect(result.aiFeedback, emptyFeedback);
      expect(result.aiScore, 0.0);
      expect(result.evaluatedAt, isNull);
    });
  });
}
