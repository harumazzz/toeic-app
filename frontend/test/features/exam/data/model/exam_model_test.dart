import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/practice/data/model/content_model.dart';
import 'package:learn/features/practice/data/model/part_model.dart';
import 'package:learn/features/practice/data/model/question_model.dart';
import 'package:learn/features/practice/domain/entities/content.dart';
import 'package:learn/features/practice/domain/entities/part.dart';
import 'package:learn/features/practice/domain/entities/question.dart';

void main() {
  group('PartModel Tests', () {
    test('should create a valid PartModel instance', () {
      const model = PartModel(
        examId: 1,
        partId: 1,
        title: 'Part 1: Photographs',
      );

      expect(model.examId, 1);
      expect(model.partId, 1);
      expect(model.title, 'Part 1: Photographs');
    });

    test('should convert PartModel to entity', () {
      const model = PartModel(
        examId: 1,
        partId: 1,
        title: 'Part 1: Photographs',
      );

      final entity = model.toEntity();

      expect(entity, isA<Part>());
      expect(entity.examId, 1);
      expect(entity.partId, 1);
      expect(entity.title, 'Part 1: Photographs');
    });

    test('should create PartModel from JSON', () {
      final json = {
        'exam_id': 1,
        'part_id': 1,
        'title': 'Part 1: Photographs',
      };

      final model = PartModel.fromJson(json);

      expect(model.examId, 1);
      expect(model.partId, 1);
      expect(model.title, 'Part 1: Photographs');
    });
  });

  group('ContentModel Tests', () {
    test('should create a valid ContentModel instance', () {
      const model = ContentModel(
        contentId: 1,
        description:
            'Look at the picture and select the statement that describes it',
        partId: 1,
        type: 'image',
      );

      expect(model.contentId, 1);
      expect(
        model.description,
        'Look at the picture and select the statement that describes it',
      );
      expect(model.partId, 1);
      expect(model.type, 'image');
    });

    test('should convert ContentModel to entity', () {
      const model = ContentModel(
        contentId: 1,
        description:
            'Look at the picture and select the statement that describes it',
        partId: 1,
        type: 'image',
      );

      final entity = model.toEntity();

      expect(entity, isA<Content>());
      expect(entity.contentId, 1);
      expect(
        entity.description,
        'Look at the picture and select the statement that describes it',
      );
      expect(entity.partId, 1);
      expect(entity.type, 'image');
    });

    test('should create ContentModel from JSON', () {
      final json = {
        'content_id': 1,
        'description':
            'Look at the picture and select the statement that describes it',
        'part_id': 1,
        'type': 'image',
      };

      final model = ContentModel.fromJson(json);

      expect(model.contentId, 1);
      expect(
        model.description,
        'Look at the picture and select the statement that describes it',
      );
      expect(model.partId, 1);
      expect(model.type, 'image');
    });
  });

  group('QuestionModel Tests', () {
    test('should create a valid QuestionModel instance', () {
      const model = QuestionModel(
        contentId: 1,
        questionId: 1,
        explanation: 'The man is reading a newspaper',
        imageUrl: 'https://example.com/image.jpg',
        keywords: 'man,reading,newspaper',
        mediaUrl: 'https://example.com/audio.mp3',
        possibleAnswers: [
          'The man is reading a newspaper',
          'The man is writing a letter',
          'The man is watching TV',
          'The man is sleeping',
        ],
        title: 'What is the man doing?',
        trueAnswer: 'The man is reading a newspaper',
      );

      expect(model.contentId, 1);
      expect(model.questionId, 1);
      expect(model.explanation, 'The man is reading a newspaper');
      expect(model.imageUrl, 'https://example.com/image.jpg');
      expect(model.keywords, 'man,reading,newspaper');
      expect(model.mediaUrl, 'https://example.com/audio.mp3');
      expect(model.possibleAnswers, [
        'The man is reading a newspaper',
        'The man is writing a letter',
        'The man is watching TV',
        'The man is sleeping',
      ]);
      expect(model.title, 'What is the man doing?');
      expect(model.trueAnswer, 'The man is reading a newspaper');
    });

    test('should convert QuestionModel to entity', () {
      const model = QuestionModel(
        contentId: 1,
        questionId: 1,
        explanation: 'The man is reading a newspaper',
        imageUrl: 'https://example.com/image.jpg',
        keywords: 'man,reading,newspaper',
        mediaUrl: 'https://example.com/audio.mp3',
        possibleAnswers: [
          'The man is reading a newspaper',
          'The man is writing a letter',
          'The man is watching TV',
          'The man is sleeping',
        ],
        title: 'What is the man doing?',
        trueAnswer: 'The man is reading a newspaper',
      );

      final entity = model.toEntity();

      expect(entity, isA<Question>());
      expect(entity.contentId, 1);
      expect(entity.questionId, 1);
      expect(entity.explanation, 'The man is reading a newspaper');
      expect(entity.imageUrl, 'https://example.com/image.jpg');
      expect(entity.keywords, 'man,reading,newspaper');
      expect(entity.mediaUrl, 'https://example.com/audio.mp3');
      expect(entity.possibleAnswers, [
        'The man is reading a newspaper',
        'The man is writing a letter',
        'The man is watching TV',
        'The man is sleeping',
      ]);
      expect(entity.title, 'What is the man doing?');
      expect(entity.trueAnswer, 'The man is reading a newspaper');
    });

    test('should create QuestionModel from JSON', () {
      final json = {
        'content_id': 1,
        'question_id': 1,
        'explanation': 'The man is reading a newspaper',
        'image_url': 'https://example.com/image.jpg',
        'keywords': 'man,reading,newspaper',
        'media_url': 'https://example.com/audio.mp3',
        'possible_answers': [
          'The man is reading a newspaper',
          'The man is writing a letter',
          'The man is watching TV',
          'The man is sleeping',
        ],
        'title': 'What is the man doing?',
        'true_answer': 'The man is reading a newspaper',
      };

      final model = QuestionModel.fromJson(json);

      expect(model.contentId, 1);
      expect(model.questionId, 1);
      expect(model.explanation, 'The man is reading a newspaper');
      expect(model.imageUrl, 'https://example.com/image.jpg');
      expect(model.keywords, 'man,reading,newspaper');
      expect(model.mediaUrl, 'https://example.com/audio.mp3');
      expect(model.possibleAnswers, [
        'The man is reading a newspaper',
        'The man is writing a letter',
        'The man is watching TV',
        'The man is sleeping',
      ]);
      expect(model.title, 'What is the man doing?');
      expect(model.trueAnswer, 'The man is reading a newspaper');
    });
  });
}
