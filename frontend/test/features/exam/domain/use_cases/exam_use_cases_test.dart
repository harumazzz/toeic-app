import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/exam/domain/entities/content.dart';
import 'package:learn/features/exam/domain/entities/part.dart';
import 'package:learn/features/exam/domain/entities/question.dart';
import 'package:learn/features/exam/domain/repositories/content_repository.dart';
import 'package:learn/features/exam/domain/repositories/part_repository.dart';
import 'package:learn/features/exam/domain/repositories/question_repository.dart';
import 'package:learn/features/exam/domain/use_cases/get_content.dart';
import 'package:learn/features/exam/domain/use_cases/get_part.dart';
import 'package:learn/features/exam/domain/use_cases/get_question.dart';
import 'package:mocktail/mocktail.dart';

class MockPartRepository extends Mock implements PartRepository {}

class MockContentRepository extends Mock implements ContentRepository {}

class MockQuestionRepository extends Mock implements QuestionRepository {}

void main() {
  late MockPartRepository mockPartRepository;
  late MockContentRepository mockContentRepository;
  late MockQuestionRepository mockQuestionRepository;
  late GetPart getPart;
  late GetPartsByExam getPartsByExam;
  late GetContent getContent;
  late GetContentByParts getContentByParts;
  late GetQuestion getQuestion;
  late GetQuestionsByContent getQuestionsByContent;

  setUp(() {
    mockPartRepository = MockPartRepository();
    mockContentRepository = MockContentRepository();
    mockQuestionRepository = MockQuestionRepository();
    getPart = GetPart(mockPartRepository);
    getPartsByExam = GetPartsByExam(mockPartRepository);
    getContent = GetContent(mockContentRepository);
    getContentByParts = GetContentByParts(mockContentRepository);
    getQuestion = GetQuestion(questionRepository: mockQuestionRepository);
    getQuestionsByContent = GetQuestionsByContent(
      questionRepository: mockQuestionRepository,
    );
  });

  group('GetPart Use Case', () {
    const testPart = Part(
      examId: 1,
      partId: 1,
      title: 'Part 1: Photographs',
    );

    test('should get part by id successfully', () async {
      when(
        () => mockPartRepository.getPartById(partId: 1),
      ).thenAnswer((_) async => const Right(testPart));

      final result = await getPart(const GetPartParams(partId: 1));

      expect(result, const Right(testPart));
      verify(() => mockPartRepository.getPartById(partId: 1)).called(1);
    });

    test('should return failure when getting part fails', () async {
      when(
        () => mockPartRepository.getPartById(partId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getPart(const GetPartParams(partId: 1));

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockPartRepository.getPartById(partId: 1)).called(1);
    });
  });

  group('GetPartsByExam Use Case', () {
    const testParts = [
      Part(
        examId: 1,
        partId: 1,
        title: 'Part 1: Photographs',
      ),
      Part(
        examId: 1,
        partId: 2,
        title: 'Part 2: Question-Response',
      ),
    ];

    test('should get parts by exam id successfully', () async {
      when(
        () => mockPartRepository.getPartsByExamId(examId: 1),
      ).thenAnswer((_) async => const Right(testParts));

      final result = await getPartsByExam(
        const GetPartsByExamParams(examId: 1),
      );

      expect(result, const Right(testParts));
      verify(() => mockPartRepository.getPartsByExamId(examId: 1)).called(1);
    });

    test('should return failure when getting parts fails', () async {
      when(
        () => mockPartRepository.getPartsByExamId(examId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getPartsByExam(
        const GetPartsByExamParams(examId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockPartRepository.getPartsByExamId(examId: 1)).called(1);
    });
  });

  group('GetContent Use Case', () {
    const testContent = Content(
      contentId: 1,
      description:
          'Look at the picture and select the statement that best describes it',
      partId: 1,
      type: 'image',
    );

    test('should get content by id successfully', () async {
      when(
        () => mockContentRepository.getContentById(contentId: 1),
      ).thenAnswer((_) async => const Right(testContent));

      final result = await getContent(const GetContentParams(contentId: 1));

      expect(result, const Right(testContent));
      verify(
        () => mockContentRepository.getContentById(contentId: 1),
      ).called(1);
    });

    test('should return failure when getting content fails', () async {
      when(
        () => mockContentRepository.getContentById(contentId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getContent(const GetContentParams(contentId: 1));

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockContentRepository.getContentById(contentId: 1),
      ).called(1);
    });
  });

  group('GetContentByParts Use Case', () {
    const testContents = [
      Content(
        contentId: 1,
        description:
            'Look at the picture and select the statement that describes it',
        partId: 1,
        type: 'image',
      ),
      Content(
        contentId: 2,
        description: 'Listen to the question and select the best response',
        partId: 1,
        type: 'audio',
      ),
    ];

    test('should get contents by part id successfully', () async {
      when(
        () => mockContentRepository.getContentByParts(partId: 1),
      ).thenAnswer((_) async => const Right(testContents));

      final result = await getContentByParts(
        const GetContentByPartsParams(partId: 1),
      );

      expect(result, const Right(testContents));
      verify(
        () => mockContentRepository.getContentByParts(partId: 1),
      ).called(1);
    });

    test('should return failure when getting contents fails', () async {
      when(
        () => mockContentRepository.getContentByParts(partId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getContentByParts(
        const GetContentByPartsParams(partId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockContentRepository.getContentByParts(partId: 1),
      ).called(1);
    });
  });

  group('GetQuestion Use Case', () {
    const testQuestion = Question(
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

    test('should get question by id successfully', () async {
      when(
        () => mockQuestionRepository.getQuestionById(questionId: 1),
      ).thenAnswer((_) async => const Right(testQuestion));

      final result = await getQuestion(const GetQuestionParams(questionId: 1));

      expect(result, const Right(testQuestion));
      verify(
        () => mockQuestionRepository.getQuestionById(questionId: 1),
      ).called(1);
    });

    test('should return failure when getting question fails', () async {
      when(
        () => mockQuestionRepository.getQuestionById(questionId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getQuestion(const GetQuestionParams(questionId: 1));

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockQuestionRepository.getQuestionById(questionId: 1),
      ).called(1);
    });
  });

  group('GetQuestionsByContent Use Case', () {
    const testQuestions = [
      Question(
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
      ),
      Question(
        contentId: 1,
        questionId: 2,
        explanation: 'The woman is typing on a computer',
        imageUrl: 'https://example.com/image2.jpg',
        keywords: 'woman,typing,computer',
        mediaUrl: 'https://example.com/audio2.mp3',
        possibleAnswers: [
          'The woman is typing on a computer',
          'The woman is reading a book',
          'The woman is talking on the phone',
          'The woman is writing on paper',
        ],
        title: 'What is the woman doing?',
        trueAnswer: 'The woman is typing on a computer',
      ),
    ];

    test('should get questions by content id successfully', () async {
      when(
        () => mockQuestionRepository.getQuestionsByContentId(contentId: 1),
      ).thenAnswer((_) async => const Right(testQuestions));

      final result = await getQuestionsByContent(
        const GetQuestionsByContentParams(contentId: 1),
      );

      expect(result, const Right(testQuestions));
      verify(
        () => mockQuestionRepository.getQuestionsByContentId(contentId: 1),
      ).called(1);
    });

    test('should return failure when getting questions fails', () async {
      when(
        () => mockQuestionRepository.getQuestionsByContentId(contentId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getQuestionsByContent(
        const GetQuestionsByContentParams(contentId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockQuestionRepository.getQuestionsByContentId(contentId: 1),
      ).called(1);
    });
  });
}
