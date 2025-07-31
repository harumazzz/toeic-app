import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammar.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammars.dart';
import 'package:learn/features/grammars/domain/use_cases/search_grammar.dart';
import 'package:learn/features/grammars/presentation/providers/grammar_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGrammars extends Mock implements GetGrammars {}

class MockGetGrammarsByLevel extends Mock implements GetGrammarsByLevel {}

class MockGetGrammarsByTag extends Mock implements GetGrammarsByTag {}

class MockSearchGrammar extends Mock implements SearchGrammar {}

class MockGetGrammar extends Mock implements GetGrammar {}

class MockGetRelatedGrammars extends Mock implements GetRelatedGrammars {}

class FakeGetGrammarsParams extends Fake implements GetGrammarsParams {}

class FakeGetGrammarsByLevelParams extends Fake
    implements GetGrammarsByLevelParams {}

class FakeGetGrammarsByTagParams extends Fake
    implements GetGrammarsByTagParams {}

class FakeSearchGrammarsParams extends Fake implements SearchGrammarsParams {}

class FakeGetGrammarParams extends Fake implements GetGrammarParams {}

class FakeGetRelatedGrammarsParams extends Fake
    implements GetRelatedGrammarsParams {}

void main() {
  late MockGetGrammars mockGetGrammars;
  late MockGetGrammarsByLevel mockGetGrammarsByLevel;
  late MockGetGrammarsByTag mockGetGrammarsByTag;
  late MockSearchGrammar mockSearchGrammar;
  late MockGetGrammar mockGetGrammar;
  late MockGetRelatedGrammars mockGetRelatedGrammars;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeGetGrammarsParams());
    registerFallbackValue(FakeGetGrammarsByLevelParams());
    registerFallbackValue(FakeGetGrammarsByTagParams());
    registerFallbackValue(FakeSearchGrammarsParams());
    registerFallbackValue(FakeGetGrammarParams());
    registerFallbackValue(FakeGetRelatedGrammarsParams());
  });

  setUp(() {
    mockGetGrammars = MockGetGrammars();
    mockGetGrammarsByLevel = MockGetGrammarsByLevel();
    mockGetGrammarsByTag = MockGetGrammarsByTag();
    mockSearchGrammar = MockSearchGrammar();
    mockGetGrammar = MockGetGrammar();
    mockGetRelatedGrammars = MockGetRelatedGrammars();

    container = ProviderContainer(
      overrides: [
        getGrammarsProvider.overrideWith((final ref) => mockGetGrammars),
        getGrammarsByLevelProvider.overrideWith(
          (final ref) => mockGetGrammarsByLevel,
        ),
        getGrammarsByTagProvider.overrideWith(
          (final ref) => mockGetGrammarsByTag,
        ),
        searchGrammarProvider.overrideWith((final ref) => mockSearchGrammar),
        getGrammarProvider.overrideWith((final ref) => mockGetGrammar),
        getRelatedGrammarsProvider.overrideWith(
          (final ref) => mockGetRelatedGrammars,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GrammarList', () {
    const tGrammar = Grammar(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
    );

    const tGrammars = [tGrammar];
    const tFailure = ServerFailure(message: 'Server error');

    group('loadGrammars', () {
      test(
        'should emit loading state and then success state',
        () async {
          // arrange
          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Right(tGrammars));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          final future = notifier.loadGrammars(limit: 10, offset: 0);

          // assert - initial state
          expect(
            container.read(grammarListProvider),
            const GrammarState(isLoading: true),
          );

          await future;

          // assert - final state
          expect(
            container.read(grammarListProvider),
            const GrammarState(
              grammars: tGrammars,
              isSuccess: true,
            ),
          );

          verify(
            () => mockGetGrammars(
              const GetGrammarsParams(limit: 10, offset: 0),
            ),
          ).called(1);
        },
      );

      test(
        'should emit loading state and then error state',
        () async {
          // arrange
          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Left(tFailure));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.loadGrammars(limit: 10, offset: 0);

          // assert
          expect(
            container.read(grammarListProvider),
            const GrammarState(
              error: 'Server error',
            ),
          );
        },
      );

      test(
        'should append new grammars to existing list when offset > 0',
        () async {
          // arrange
          const existingGrammar = Grammar(
            id: 2,
            grammarKey: 'past-simple',
            title: 'Past Simple Tense',
            level: 1,
          );
          const newGrammar = Grammar(
            id: 3,
            grammarKey: 'future-simple',
            title: 'Future Simple Tense',
            level: 2,
          );

          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Right([existingGrammar]));

          final notifier = container.read(grammarListProvider.notifier);
          await notifier.loadGrammars(limit: 10, offset: 0);

          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Right([newGrammar]));

          // act
          await notifier.loadGrammars(limit: 10, offset: 10);

          // assert
          expect(
            container.read(grammarListProvider).grammars,
            [existingGrammar, newGrammar],
          );
        },
      );

      test(
        'should return early when offset > 0',
        () async {
          // arrange
          final notifier = container.read(grammarListProvider.notifier)
            ..state = const GrammarState(
              isSuccess: true,
            );

          // act
          await notifier.loadGrammars(limit: 10, offset: 10);

          // assert
          verifyNever(() => mockGetGrammars(any()));
        },
      );
    });

    group('loadGrammarsByLevel', () {
      test(
        'should call GetGrammarsByLevel use case with correct parameters',
        () async {
          // arrange
          when(
            () => mockGetGrammarsByLevel(any()),
          ).thenAnswer((_) async => const Right(tGrammars));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.loadGrammarsByLevel(
            level: 1,
            limit: 10,
            offset: 0,
          );

          // assert
          verify(
            () => mockGetGrammarsByLevel(
              const GetGrammarsByLevelParams(
                level: 1,
                limit: 10,
                offset: 0,
              ),
            ),
          ).called(1);

          expect(
            container.read(grammarListProvider),
            const GrammarState(
              grammars: tGrammars,
              isSuccess: true,
            ),
          );
        },
      );

      test(
        'should emit error state when GetGrammarsByLevel fails',
        () async {
          // arrange
          when(
            () => mockGetGrammarsByLevel(any()),
          ).thenAnswer((_) async => const Left(tFailure));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.loadGrammarsByLevel(
            level: 1,
            limit: 10,
            offset: 0,
          );

          // assert
          expect(
            container.read(grammarListProvider),
            const GrammarState(
              error: 'Server error',
            ),
          );
        },
      );
    });

    group('loadGrammarsByTag', () {
      test(
        'should call GetGrammarsByTag use case with correct parameters',
        () async {
          // arrange
          when(
            () => mockGetGrammarsByTag(any()),
          ).thenAnswer((_) async => const Right(tGrammars));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.loadGrammarsByTag(
            tag: 1,
            limit: 10,
            offset: 0,
          );

          // assert
          verify(
            () => mockGetGrammarsByTag(
              const GetGrammarsByTagParams(
                tag: 1,
                limit: 10,
                offset: 0,
              ),
            ),
          ).called(1);

          expect(
            container.read(grammarListProvider),
            const GrammarState(
              grammars: tGrammars,
              isSuccess: true,
            ),
          );
        },
      );

      test(
        'should emit error state when GetGrammarsByTag fails',
        () async {
          // arrange
          when(
            () => mockGetGrammarsByTag(any()),
          ).thenAnswer((_) async => const Left(tFailure));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.loadGrammarsByTag(
            tag: 1,
            limit: 10,
            offset: 0,
          );

          // assert
          expect(
            container.read(grammarListProvider),
            const GrammarState(
              error: 'Server error',
            ),
          );
        },
      );
    });

    group('searchGrammars', () {
      test(
        'should call SearchGrammar use case with correct parameters',
        () async {
          // arrange
          when(
            () => mockSearchGrammar(any()),
          ).thenAnswer((_) async => const Right(tGrammars));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.searchGrammars(
            query: 'present',
            limit: 10,
            offset: 0,
          );

          // assert
          verify(
            () => mockSearchGrammar(
              const SearchGrammarsParams(
                query: 'present',
                limit: 10,
                offset: 0,
              ),
            ),
          ).called(1);

          expect(
            container.read(grammarListProvider),
            const GrammarState(
              grammars: tGrammars,
              isSuccess: true,
            ),
          );
        },
      );

      test(
        'should emit error state when SearchGrammar fails',
        () async {
          // arrange
          when(
            () => mockSearchGrammar(any()),
          ).thenAnswer((_) async => const Left(tFailure));

          final notifier = container.read(grammarListProvider.notifier);

          // act
          await notifier.searchGrammars(
            query: 'present',
            limit: 10,
            offset: 0,
          );

          // assert
          expect(
            container.read(grammarListProvider),
            const GrammarState(
              error: 'Server error',
            ),
          );
        },
      );
    });
  });

  group('GrammarDetail', () {
    const tRelatedGrammar = Grammar(
      id: 2,
      grammarKey: 'past-simple',
      title: 'Past Simple Tense',
      level: 1,
    );

    const tRelatedGrammars = [tRelatedGrammar];
    const tFailure = ServerFailure(message: 'Server error');

    group('loadRelatedGrammars', () {
      test(
        'should load related grammars successfully',
        () async {
          // arrange
          when(
            () => mockGetRelatedGrammars(any()),
          ).thenAnswer((_) async => const Right(tRelatedGrammars));

          final notifier = container.read(grammarDetailProvider.notifier);

          // act
          await notifier.loadRelatedGrammars([2, 3]);

          // assert
          expect(
            container.read(grammarDetailProvider).relatedGrammars,
            tRelatedGrammars,
          );

          verify(
            () => mockGetRelatedGrammars(
              const GetRelatedGrammarsParams(ids: [2, 3]),
            ),
          ).called(1);
        },
      );

      test(
        'should emit error when related grammars loading fails',
        () async {
          // arrange
          when(
            () => mockGetRelatedGrammars(any()),
          ).thenAnswer((_) async => const Left(tFailure));

          final notifier = container.read(grammarDetailProvider.notifier);

          // act
          await notifier.loadRelatedGrammars([2, 3]);

          // assert
          expect(
            container.read(grammarDetailProvider).error,
            'Server error',
          );
        },
      );
    });
  });
}
