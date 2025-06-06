import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/repositories/grammar_repository.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammars.dart';
import 'package:mocktail/mocktail.dart';

class MockGrammarRepository extends Mock implements GrammarRepository {}

void main() {
  late GetGrammars getGrammarsUseCase;
  late GetGrammarsByLevel getGrammarsByLevelUseCase;
  late GetGrammarsByTag getGrammarsByTagUseCase;
  late MockGrammarRepository mockGrammarRepository;

  setUp(() {
    mockGrammarRepository = MockGrammarRepository();
    getGrammarsUseCase = GetGrammars(mockGrammarRepository);
    getGrammarsByLevelUseCase = GetGrammarsByLevel(mockGrammarRepository);
    getGrammarsByTagUseCase = GetGrammarsByTag(mockGrammarRepository);
  });

  const tLimit = 10;
  const tOffset = 0;
  const tGrammars = [
    Grammar(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    ),
    Grammar(
      id: 2,
      title: 'Past Simple',
      grammarKey: 'past_simple',
      level: 3,
    ),
  ];

  group('GetGrammars', () {
    const tParams = GetGrammarsParams(limit: tLimit, offset: tOffset);

    test(
      'should get all grammars from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getAllGrammars(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right(tGrammars));

        // act
        final result = await getGrammarsUseCase(tParams);

        // assert
        expect(result, const Right(tGrammars));
        verify(
          () => mockGrammarRepository.getAllGrammars(
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository call fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Failed to fetch grammars',
        );

        when(
          () => mockGrammarRepository.getAllGrammars(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await getGrammarsUseCase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockGrammarRepository.getAllGrammars(
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  group('GetGrammarsByLevel', () {
    const tLevel = 2;
    const tParams = GetGrammarsByLevelParams(
      level: tLevel,
      limit: tLimit,
      offset: tOffset,
    );

    test(
      'should get grammars by level from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getAllGrammarsByLevel(
            level: any(named: 'level'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right(tGrammars));

        // act
        final result = await getGrammarsByLevelUseCase(tParams);

        // assert
        expect(result, const Right(tGrammars));
        verify(
          () => mockGrammarRepository.getAllGrammarsByLevel(
            level: tLevel,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository call fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Failed to fetch grammars by level',
        );

        when(
          () => mockGrammarRepository.getAllGrammarsByLevel(
            level: any(named: 'level'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await getGrammarsByLevelUseCase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockGrammarRepository.getAllGrammarsByLevel(
            level: tLevel,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  group('GetGrammarsByTag', () {
    const tTag = 1;
    const tParams = GetGrammarsByTagParams(
      tag: tTag,
      limit: tLimit,
      offset: tOffset,
    );

    test(
      'should get grammars by tag from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getAllGrammarsByTag(
            tag: any(named: 'tag'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right(tGrammars));

        // act
        final result = await getGrammarsByTagUseCase(tParams);

        // assert
        expect(result, const Right(tGrammars));
        verify(
          () => mockGrammarRepository.getAllGrammarsByTag(
            tag: tTag,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository call fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Failed to fetch grammars by tag',
        );

        when(
          () => mockGrammarRepository.getAllGrammarsByTag(
            tag: any(named: 'tag'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await getGrammarsByTagUseCase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockGrammarRepository.getAllGrammarsByTag(
            tag: tTag,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });
}
