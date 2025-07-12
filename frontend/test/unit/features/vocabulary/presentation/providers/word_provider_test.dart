import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/use_cases/get_all_word.dart';
import 'package:learn/features/vocabulary/domain/use_cases/search_word.dart';
import 'package:learn/features/vocabulary/presentation/providers/word_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllWord extends Mock implements GetAllWord {}

class MockSearchWord extends Mock implements SearchWord {}

void main() {
  group('WordController', () {
    late ProviderContainer container;
    late MockGetAllWord mockGetAllWord;
    late MockSearchWord mockSearchWord;

    setUp(() {
      mockGetAllWord = MockGetAllWord();
      mockSearchWord = MockSearchWord();

      container = ProviderContainer(
        overrides: [
          getAllWordProvider.overrideWithValue(mockGetAllWord),
          searchWordProvider.overrideWithValue(mockSearchWord),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    setUpAll(() {
      registerFallbackValue(const GetAllWordParams(offset: 0, limit: 20));
      registerFallbackValue(
        const SearchWordParams(query: '', offset: 0, limit: 20),
      );
    });

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

    group('initial state', () {
      test('should start with initial state and empty words', () {
        // act
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordInitial>());
        expect(state.words, isEmpty);
      });
    });

    group('loadWords', () {
      test('should load words successfully', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // act
        await container.read(wordControllerProvider.notifier).loadWords();
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words, equals(tWords));
        expect((state as WordLoaded).isFinished, isFalse);
      });

      test('should handle empty words list', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(<Word>[]),
        );

        // act
        await container.read(wordControllerProvider.notifier).loadWords();
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words, isEmpty);
        expect((state as WordLoaded).isFinished, isTrue);
      });

      test('should handle failure', () async {
        // arrange
        const tFailure = Failure.serverFailure(message: 'Server error');
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        // act
        await container.read(wordControllerProvider.notifier).loadWords();
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordError>());
        expect((state as WordError).message, equals('Server error'));
        expect(state.words, isEmpty);
      });

      test('should append words when loading more', () async {
        // arrange
        const tAdditionalWords = [
          Word(
            id: 3,
            word: 'additional',
            pronounce: 'əˈdɪʃənəl',
            level: 1,
            descriptLevel: 'A1',
            shortMean: 'extra',
            freq: 90,
            means: [],
            snym: [],
          ),
        ];

        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // Load initial words
        await container.read(wordControllerProvider.notifier).loadWords();

        // Setup for loading more words
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tAdditionalWords),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .loadWords(offset: 20);
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words.length, equals(3)); // Original 2 + additional 1
        expect(state.words, contains(tAdditionalWords.first));
      });

      test('should call GetAllWord with correct parameters', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .loadWords(
              offset: 10,
              limit: 30,
            );

        // assert
        verify(
          () => mockGetAllWord(const GetAllWordParams(offset: 10, limit: 30)),
        ).called(1);
      });

      test('should not load if already loading', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return const Right(tWords);
          },
        );

        // act
        final future1 = container
            .read(wordControllerProvider.notifier)
            .loadWords();
        final future2 = container
            .read(wordControllerProvider.notifier)
            .loadWords();

        await Future.wait([future1, future2]);

        // assert
        verify(
          () => mockGetAllWord(any()),
        ).called(1); // Should only be called once
      });
    });

    group('refreshWords', () {
      test('should reset words and load fresh data', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // Load initial words
        await container.read(wordControllerProvider.notifier).loadWords();
        expect(container.read(wordControllerProvider).words, isNotEmpty);

        // act
        await container.read(wordControllerProvider.notifier).refreshWords();
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words, equals(tWords));
        verify(
          () => mockGetAllWord(any()),
        ).called(2); // Once for initial load, once for refresh
      });
    });

    group('searchWords', () {
      test('should search words successfully', () async {
        // arrange
        const tQuery = 'example';
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words, equals(tWords));
        expect((state as WordLoaded).isFinished, isFalse);
        verify(
          () => mockSearchWord(
            const SearchWordParams(
              query: tQuery,
              offset: 0,
              limit: 20,
            ),
          ),
        ).called(1);
      });

      test('should handle empty search results', () async {
        // arrange
        const tQuery = 'nonexistent';
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async => const Right(<Word>[]),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words, isEmpty);
        expect((state as WordLoaded).isFinished, isTrue);
      });

      test('should handle search failure', () async {
        // arrange
        const tQuery = 'example';
        const tFailure = Failure.networkFailure(message: 'Network error');
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordError>());
        expect((state as WordError).message, equals('Network error'));
      });

      test('should append search results when loading more', () async {
        // arrange
        const tQuery = 'example';
        const tAdditionalWords = [
          Word(
            id: 3,
            word: 'example advanced',
            pronounce: 'ɪɡˈzæmpəl ədˈvænst',
            level: 2,
            descriptLevel: 'A2',
            shortMean: 'advanced example',
            freq: 70,
            means: [],
            snym: [],
          ),
        ];

        // First search
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );
        await container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );

        // Second search (load more)
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async => const Right(tAdditionalWords),
        );

        // act
        await container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 20,
            );
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordLoaded>());
        expect(state.words.length, equals(3)); // Original 2 + additional 1
      });

      test('should not search if already loading', () async {
        // arrange
        const tQuery = 'example';
        when(() => mockSearchWord(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return const Right(tWords);
          },
        );

        // act
        final future1 = container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );
        final future2 = container
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: tQuery,
              offset: 0,
            );

        await Future.wait([future1, future2]);

        // assert
        verify(
          () => mockSearchWord(any()),
        ).called(1); // Should only be called once
      });
    });

    group('reset', () {
      test('should reset state to initial', () async {
        // arrange
        when(() => mockGetAllWord(any())).thenAnswer(
          (_) async => const Right(tWords),
        );

        // Load some words first
        await container.read(wordControllerProvider.notifier).loadWords();
        expect(container.read(wordControllerProvider).words, isNotEmpty);

        // act
        container.read(wordControllerProvider.notifier).reset();
        final state = container.read(wordControllerProvider);

        // assert
        expect(state, isA<WordInitial>());
        expect(state.words, isEmpty);
      });
    });
  });
}
