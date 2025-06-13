import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/practice/domain/entities/question.dart';
import 'package:learn/features/practice/domain/repositories/question_repository.dart';
import 'package:learn/features/practice/domain/use_cases/get_question.dart';
import 'package:mocktail/mocktail.dart';

class MockQuestionRepository extends Mock implements QuestionRepository {}

void main() {
  late MockQuestionRepository mockRepository;
  late GetQuestion getQuestion;
  late GetQuestionsByContent getQuestionsByContent;

  setUp(() {
    mockRepository = MockQuestionRepository();
    getQuestion = GetQuestion(questionRepository: mockRepository);
    getQuestionsByContent = GetQuestionsByContent(
      questionRepository: mockRepository,
    );
  });

  group('GetQuestion', () {
    const testQuestion = Question(
      contentId: 1,
      questionId: 1,
      explanation: 'Test Explanation',
      imageUrl: 'https://example.com/image.jpg',
      keywords: 'test,keywords',
      mediaUrl: 'https://example.com/media.mp3',
      possibleAnswers: ['A', 'B', 'C', 'D'],
      title: 'Test Question',
      trueAnswer: 'A',
    );

    test('should get question by id successfully', () async {
      // arrange
      when(
        () => mockRepository.getQuestionById(questionId: 1),
      ).thenAnswer((_) async => const Right(testQuestion));

      // act
      final result = await getQuestion(const GetQuestionParams(questionId: 1));

      // assert
      expect(result, const Right(testQuestion));
      verify(() => mockRepository.getQuestionById(questionId: 1)).called(1);
    });

    test('should return failure when getting question fails', () async {
      // arrange
      when(
        () => mockRepository.getQuestionById(questionId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getQuestion(const GetQuestionParams(questionId: 1));

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getQuestionById(questionId: 1)).called(1);
    });
  });

  group('GetQuestionsByContent', () {
    const testQuestions = [
      Question(
        contentId: 1,
        questionId: 1,
        explanation: 'Test Explanation 1',
        imageUrl: 'https://example.com/image1.jpg',
        keywords: 'test1,keywords1',
        mediaUrl: 'https://example.com/media1.mp3',
        possibleAnswers: ['A', 'B', 'C', 'D'],
        title: 'Test Question 1',
        trueAnswer: 'A',
      ),
      Question(
        contentId: 1,
        questionId: 2,
        explanation: 'Test Explanation 2',
        imageUrl: 'https://example.com/image2.jpg',
        keywords: 'test2,keywords2',
        mediaUrl: 'https://example.com/media2.mp3',
        possibleAnswers: ['A', 'B', 'C', 'D'],
        title: 'Test Question 2',
        trueAnswer: 'B',
      ),
    ];

    test('should get questions by content id successfully', () async {
      // arrange
      when(
        () => mockRepository.getQuestionsByContentId(contentId: 1),
      ).thenAnswer((_) async => const Right(testQuestions));

      // act
      final result = await getQuestionsByContent(
        const GetQuestionsByContentParams(contentId: 1),
      );

      // assert
      expect(result, const Right(testQuestions));
      verify(
        () => mockRepository.getQuestionsByContentId(contentId: 1),
      ).called(1);
    });

    test('should return failure when getting questions fails', () async {
      // arrange
      when(
        () => mockRepository.getQuestionsByContentId(contentId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getQuestionsByContent(
        const GetQuestionsByContentParams(contentId: 1),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockRepository.getQuestionsByContentId(contentId: 1),
      ).called(1);
    });
  });
}
