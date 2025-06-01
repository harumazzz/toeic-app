import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/repositories/word_repository.dart';
import 'package:learn/features/vocabulary/domain/use_cases/get_all_word.dart';
import 'package:mocktail/mocktail.dart';

class MockWordRepository extends Mock implements WordRepository {}

void main() {
  late GetAllWord usecase;
  late MockWordRepository mockWordRepository;

  setUp(() {
    mockWordRepository = MockWordRepository();
    usecase = GetAllWord(mockWordRepository);
  });

  group('GetAllWord Use Case', () {
    const tOffset = 0;
    const tLimit = 10;
    const tWords = [
      Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      ),
      Word(
        id: 2,
        word: 'test',
        pronounce: 'test',
        level: 2,
        descriptLevel: 'A2',
        shortMean: 'test meaning',
        freq: 80,
        means: [],
        snym: [],
      ),
    ];
    const tParams = GetAllWordParams(offset: tOffset, limit: tLimit);

    test(
      'should get words from the repository when call is successful',
      () async {
        // arrange
        when(
          () => mockWordRepository.getAllWords(
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(tWords));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tWords));
        verify(
          () => mockWordRepository.getAllWords(
            offset: tOffset,
            limit: tLimit,
          ),
        );
        verifyNoMoreInteractions(mockWordRepository);
      },
    );

    test('should return empty list when no words found', () async {
      // arrange
      const tEmptyWords = <Word>[];
      when(
        () => mockWordRepository.getAllWords(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(tEmptyWords));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(tEmptyWords));
      verify(
        () => mockWordRepository.getAllWords(
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Words not found',
      );
      when(
        () => mockWordRepository.getAllWords(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.getAllWords(
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(message: 'Network error');
      when(
        () => mockWordRepository.getAllWords(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.getAllWords(
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should return server failure when server error occurs', () async {
      // arrange
      const tFailure = Failure.serverFailure(message: 'Server error');
      when(
        () => mockWordRepository.getAllWords(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.getAllWords(
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should handle different pagination parameters', () async {
      // arrange
      const tCustomOffset = 20;
      const tCustomLimit = 5;
      const tCustomParams = GetAllWordParams(
        offset: tCustomOffset,
        limit: tCustomLimit,
      );

      when(
        () => mockWordRepository.getAllWords(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(tWords));

      // act
      final result = await usecase(tCustomParams);

      // assert
      expect(result, const Right(tWords));
      verify(
        () => mockWordRepository.getAllWords(
          offset: tCustomOffset,
          limit: tCustomLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });
  });

  group('GetAllWordParams', () {
    test('should create GetAllWordParams with correct values', () {
      // arrange
      const tOffset = 0;
      const tLimit = 10;

      // act
      const params = GetAllWordParams(offset: tOffset, limit: tLimit);

      // assert
      expect(params.offset, tOffset);
      expect(params.limit, tLimit);
    });

    test('should support equality comparison', () {
      // arrange
      const tOffset = 0;
      const tLimit = 10;

      // act
      const params1 = GetAllWordParams(offset: tOffset, limit: tLimit);
      const params2 = GetAllWordParams(offset: tOffset, limit: tLimit);

      // assert
      expect(params1, params2);
      expect(params1.hashCode, params2.hashCode);
    });

    test('should not be equal with different values', () {
      // arrange
      const params1 = GetAllWordParams(offset: 0, limit: 10);
      const params2 = GetAllWordParams(offset: 10, limit: 20);

      // assert
      expect(params1, isNot(params2));
      expect(params1.hashCode, isNot(params2.hashCode));
    });
  });
}
