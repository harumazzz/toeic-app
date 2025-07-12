import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/use_cases/get_word.dart';
import 'package:learn/features/vocabulary/presentation/providers/word_detail_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWord extends Mock implements GetWord {}

void main() {
  group('WordDetailController', () {
    late ProviderContainer container;
    late MockGetWord mockGetWord;

    setUp(() {
      mockGetWord = MockGetWord();

      container = ProviderContainer(
        overrides: [
          getWordProvider.overrideWithValue(mockGetWord),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    setUpAll(() {
      registerFallbackValue(const GetWordParams(id: 1));
    });

    const tWord = Word(
      id: 1,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
      means: [],
      snym: [],
    );

    group('initial state', () {
      test('should start with initial state', () {
        // act
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailInitial>());
      });
    });

    group('loadWord', () {
      test('should load word successfully', () async {
        // arrange
        const wordId = 1;
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Right(tWord),
        );

        // act
        await container
            .read(
              wordDetailControllerProvider.notifier,
            )
            .loadWord(wordId);
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailLoaded>());
        expect((state as WordDetailLoaded).word, equals(tWord));
        verify(() => mockGetWord(const GetWordParams(id: wordId))).called(1);
      });

      test('should handle word loading failure', () async {
        // arrange
        const wordId = 1;
        const tFailure = Failure.serverFailure(message: 'Word not found');
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        // act
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailError>());
        expect((state as WordDetailError).message, equals('Word not found'));
        verify(() => mockGetWord(const GetWordParams(id: wordId))).called(1);
      });

      test('should not reload if already loading', () async {
        // arrange
        const wordId = 1;
        when(() => mockGetWord(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return const Right(tWord);
          },
        );

        // act
        final future1 = container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);
        final future2 = container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);

        await Future.wait([future1, future2]);

        // assert
        verify(
          () => mockGetWord(any()),
        ).called(1); // Should only be called once
      });

      test('should not reload if same word is already loaded', () async {
        // arrange
        const wordId = 1;
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Right(tWord),
        );

        // Load word first time
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);

        // act - try to load same word again
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);

        // assert
        verify(
          () => mockGetWord(any()),
        ).called(1); // Should only be called once
      });

      test('should reload if different word is requested', () async {
        // arrange
        const wordId1 = 1;
        const wordId2 = 2;
        const tWord2 = Word(
          id: 2,
          word: 'test',
          pronounce: 'test',
          level: 2,
          descriptLevel: 'A2',
          shortMean: 'test meaning',
          freq: 80,
          means: [],
          snym: [],
        );

        when(() => mockGetWord(any())).thenAnswer((final invocation) async {
          final params = invocation.positionalArguments[0] as GetWordParams;
          if (params.id == wordId1) {
            return const Right(tWord);
          } else {
            return const Right(tWord2);
          }
        });

        // Load first word
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId1);

        // act - load different word
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId2);
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailLoaded>());
        expect((state as WordDetailLoaded).word, equals(tWord2));
        verify(() => mockGetWord(any())).called(2); // Should be called twice
      });

      test('should set loading state before making request', () async {
        // arrange
        const wordId = 1;
        when(() => mockGetWord(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return const Right(tWord);
          },
        );

        // act
        final future = container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);

        // Check state immediately after calling loadWord
        final loadingState = container.read(wordDetailControllerProvider);
        expect(loadingState, isA<WordDetailLoading>());

        await future;
        final finalState = container.read(wordDetailControllerProvider);
        expect(finalState, isA<WordDetailLoaded>());
      });

      test('should handle network failure', () async {
        // arrange
        const wordId = 1;
        const tFailure = Failure.networkFailure(
          message: 'Network connection failed',
        );
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        // act
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailError>());
        expect(
          (state as WordDetailError).message,
          equals('Network connection failed'),
        );
      });

      test('should handle server failure', () async {
        // arrange
        const wordId = 1;
        const tFailure = Failure.serverFailure(
          message: 'Internal server error',
        );
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        // act
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);
        final state = container.read(wordDetailControllerProvider);

        // assert
        expect(state, isA<WordDetailError>());
        expect(
          (state as WordDetailError).message,
          equals('Internal server error'),
        );
      });

      test('should call GetWord with correct parameters', () async {
        // arrange
        const wordId = 123;
        when(() => mockGetWord(any())).thenAnswer(
          (_) async => const Right(tWord),
        );

        // act
        await container
            .read(wordDetailControllerProvider.notifier)
            .loadWord(wordId);

        // assert
        verify(() => mockGetWord(const GetWordParams(id: wordId))).called(1);
      });
    });
  });
}
