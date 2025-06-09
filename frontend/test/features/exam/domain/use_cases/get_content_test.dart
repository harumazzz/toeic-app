import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/exam/domain/entities/content.dart';
import 'package:learn/features/exam/domain/repositories/content_repository.dart';
import 'package:learn/features/exam/domain/use_cases/get_content.dart';
import 'package:mocktail/mocktail.dart';

class MockContentRepository extends Mock implements ContentRepository {}

void main() {
  late MockContentRepository mockRepository;
  late GetContent getContent;
  late GetContentByParts getContentByParts;

  setUp(() {
    mockRepository = MockContentRepository();
    getContent = GetContent(mockRepository);
    getContentByParts = GetContentByParts(mockRepository);
  });

  group('GetContent', () {
    const testContent = Content(
      contentId: 1,
      description: 'Test Description',
      partId: 1,
      type: 'text',
    );

    test('should get content by id successfully', () async {
      // arrange
      when(
        () => mockRepository.getContentById(contentId: 1),
      ).thenAnswer((_) async => const Right(testContent));

      // act
      final result = await getContent(const GetContentParams(contentId: 1));

      // assert
      expect(result, const Right(testContent));
      verify(() => mockRepository.getContentById(contentId: 1)).called(1);
    });

    test('should return failure when getting content fails', () async {
      // arrange
      when(
        () => mockRepository.getContentById(contentId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getContent(const GetContentParams(contentId: 1));

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getContentById(contentId: 1)).called(1);
    });
  });

  group('GetContentByParts', () {
    const testContents = [
      Content(
        contentId: 1,
        description: 'Test Description 1',
        partId: 1,
        type: 'text',
      ),
      Content(
        contentId: 2,
        description: 'Test Description 2',
        partId: 1,
        type: 'audio',
      ),
    ];

    test('should get contents by part id successfully', () async {
      // arrange
      when(
        () => mockRepository.getContentByParts(partId: 1),
      ).thenAnswer((_) async => const Right(testContents));

      // act
      final result = await getContentByParts(
        const GetContentByPartsParams(partId: 1),
      );

      // assert
      expect(result, const Right(testContents));
      verify(() => mockRepository.getContentByParts(partId: 1)).called(1);
    });

    test('should return failure when getting contents fails', () async {
      // arrange
      when(
        () => mockRepository.getContentByParts(partId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getContentByParts(
        const GetContentByPartsParams(partId: 1),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getContentByParts(partId: 1)).called(1);
    });
  });
}
