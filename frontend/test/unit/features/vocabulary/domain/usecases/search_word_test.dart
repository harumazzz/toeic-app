import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/repositories/word_repository.dart';
import 'package:learn/features/vocabulary/domain/use_cases/search_word.dart';
import 'package:mocktail/mocktail.dart';

class MockWordRepository extends Mock implements WordRepository {}

void main() {
  late SearchWord usecase;
  late MockWordRepository mockWordRepository;

  setUpAll(() {
    registerFallbackValue(
      const SearchWordParams(query: '', offset: 0, limit: 10),
    );
  });

  setUp(() {
    mockWordRepository = MockWordRepository();
    usecase = SearchWord(mockWordRepository);
  });

  group('SearchWord Use Case', () {
    const tQuery = 'example';
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
        word: 'example test',
        pronounce: 'ɪɡˈzæmpəl test',
        level: 2,
        descriptLevel: 'A2',
        shortMean: 'test meaning',
        freq: 80,
        means: [],
        snym: [],
      ),
    ];
    const tParams = SearchWordParams(
      query: tQuery,
      offset: tOffset,
      limit: tLimit,
    );

    test(
      'should search words from the repository when call is successful',
      () async {
        // arrange
        when(
          () => mockWordRepository.searchWords(
            query: any(named: 'query'),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(tWords));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tWords));
        verify(
          () => mockWordRepository.searchWords(
            query: tQuery,
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
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(tEmptyWords));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(tEmptyWords));
      verify(
        () => mockWordRepository.searchWords(
          query: tQuery,
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
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.searchWords(
          query: tQuery,
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
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.searchWords(
          query: tQuery,
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should handle different search parameters', () async {
      // arrange
      const tCustomQuery = 'test';
      const tCustomOffset = 20;
      const tCustomLimit = 5;
      const tCustomParams = SearchWordParams(
        query: tCustomQuery,
        offset: tCustomOffset,
        limit: tCustomLimit,
      );

      when(
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(tWords));

      // act
      final result = await usecase(tCustomParams);

      // assert
      expect(result, const Right(tWords));
      verify(
        () => mockWordRepository.searchWords(
          query: tCustomQuery,
          offset: tCustomOffset,
          limit: tCustomLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should handle network failure', () async {
      // arrange
      const tFailure = Failure.networkFailure(
        message: 'Network connection failed',
      );
      when(
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockWordRepository.searchWords(
          query: tQuery,
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should search with empty query', () async {
      // arrange
      const tEmptyQuery = '';
      const tEmptyParams = SearchWordParams(
        query: tEmptyQuery,
        offset: tOffset,
        limit: tLimit,
      );

      when(
        () => mockWordRepository.searchWords(
          query: any(named: 'query'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(<Word>[]));

      // act
      final result = await usecase(tEmptyParams);

      // assert
      expect(result, const Right(<Word>[]));
      verify(
        () => mockWordRepository.searchWords(
          query: tEmptyQuery,
          offset: tOffset,
          limit: tLimit,
        ),
      );
      verifyNoMoreInteractions(mockWordRepository);
    });
  });
}
