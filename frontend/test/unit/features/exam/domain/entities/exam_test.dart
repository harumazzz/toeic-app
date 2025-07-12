import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/practice/domain/entities/content.dart';
import 'package:learn/features/practice/domain/entities/part.dart';
import 'package:learn/features/practice/domain/entities/question.dart';

void main() {
  group('Part Entity Tests', () {
    test('should create a valid Part instance', () {
      const part = Part(
        examId: 1,
        partId: 1,
        title: 'Part 1: Photographs',
      );

      expect(part.examId, 1);
      expect(part.partId, 1);
      expect(part.title, 'Part 1: Photographs');
    });
  });

  group('Content Entity Tests', () {
    test('should create a valid Content instance', () {
      const content = Content(
        contentId: 1,
        description:
            'Look at the picture and select the statement that describes it',
        partId: 1,
        type: 'image',
      );

      expect(content.contentId, 1);
      expect(
        content.description,
        'Look at the picture and select the statement that describes it',
      );
      expect(content.partId, 1);
      expect(content.type, 'image');
    });
  });

  group('Question Entity Tests', () {
    test('should create a valid Question instance', () {
      const question = Question(
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

      expect(question.contentId, 1);
      expect(question.questionId, 1);
      expect(question.explanation, 'The man is reading a newspaper');
      expect(question.imageUrl, 'https://example.com/image.jpg');
      expect(question.keywords, 'man,reading,newspaper');
      expect(question.mediaUrl, 'https://example.com/audio.mp3');
      expect(question.possibleAnswers, [
        'The man is reading a newspaper',
        'The man is writing a letter',
        'The man is watching TV',
        'The man is sleeping',
      ]);
      expect(question.title, 'What is the man doing?');
      expect(question.trueAnswer, 'The man is reading a newspaper');
    });
  });
}
