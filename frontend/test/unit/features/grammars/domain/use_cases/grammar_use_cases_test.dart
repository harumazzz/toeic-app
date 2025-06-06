import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/core/use_cases/use_case.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/repositories/grammar_repository.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammar.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammars.dart';
import 'package:learn/features/grammars/domain/use_cases/search_grammar.dart';
import 'package:mocktail/mocktail.dart';

class MockGrammarRepository extends Mock implements GrammarRepository {}

void main() {
  late MockGrammarRepository mockGrammarRepository;

  // Sample test data
  const tGrammar = Grammar(
    id: 1,
    title: 'Present Simple',
    grammarKey: 'present_simple',
    level: 2,
  );

  const tGrammars = [
    Grammar(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    ),
    Grammar(id: 2, title: 'Past Simple', grammarKey: 'past_simple', level: 3),
  ];

  setUp(() {
    mockGrammarRepository = MockGrammarRepository();
  });

  group('GetGrammar', () {
    late GetGrammar usecase;
    const tId = 1;
    const tParams = GetGrammarParams(id: tId);

    setUp(() {
      usecase = GetGrammar(mockGrammarRepository);
    });

    test(
      'should get grammar from repository by ID when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getGrammarById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(tGrammar));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tGrammar));
        verify(() => mockGrammarRepository.getGrammarById(id: tId));
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository call fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Grammar not found',
        );

        when(
          () => mockGrammarRepository.getGrammarById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockGrammarRepository.getGrammarById(id: tId));
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  group('GetRandomGrammar', () {
    late GetRandomGrammar usecase;
    const tParams = NoParams();

    setUp(() {
      usecase = GetRandomGrammar(mockGrammarRepository);
    });

    test(
      'should get a random grammar from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getRandomGrammar(),
        ).thenAnswer((_) async => const Right(tGrammar));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tGrammar));
        verify(() => mockGrammarRepository.getRandomGrammar());
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository call fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Failed to fetch random grammar',
        );

        when(
          () => mockGrammarRepository.getRandomGrammar(),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockGrammarRepository.getRandomGrammar());
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  group('GetGrammars', () {
    late GetGrammars usecase;
    const tLimit = 10;
    const tOffset = 0;
    const tParams = GetGrammarsParams(limit: tLimit, offset: tOffset);

    setUp(() {
      usecase = GetGrammars(mockGrammarRepository);
    });

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
        final result = await usecase(tParams);

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
        final result = await usecase(tParams);

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
    late GetGrammarsByLevel usecase;
    const tLevel = 2;
    const tLimit = 10;
    const tOffset = 0;
    const tParams = GetGrammarsByLevelParams(
      level: tLevel,
      limit: tLimit,
      offset: tOffset,
    );

    setUp(() {
      usecase = GetGrammarsByLevel(mockGrammarRepository);
    });

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
        final result = await usecase(tParams);

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
        final result = await usecase(tParams);

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
    late GetGrammarsByTag usecase;
    const tTag = 1;
    const tLimit = 10;
    const tOffset = 0;
    const tParams = GetGrammarsByTagParams(
      tag: tTag,
      limit: tLimit,
      offset: tOffset,
    );

    setUp(() {
      usecase = GetGrammarsByTag(mockGrammarRepository);
    });

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
        final result = await usecase(tParams);

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
        final result = await usecase(tParams);

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

  group('SearchGrammar', () {
    late SearchGrammar usecase;
    const tQuery = 'present';
    const tLimit = 10;
    const tOffset = 0;
    const tParams = SearchGrammarsParams(
      query: tQuery,
      limit: tLimit,
      offset: tOffset,
    );

    setUp(() {
      usecase = SearchGrammar(mockGrammarRepository);
    });

    test(
      'should get grammars from repository when search is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.searchGrammars(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right(tGrammars));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tGrammars));
        verify(
          () => mockGrammarRepository.searchGrammars(
            query: tQuery,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );

    test(
      'should return server failure when repository search fails',
      () async {
        // arrange
        const tFailure = Failure.serverFailure(
          message: 'Failed to search grammars',
        );

        when(
          () => mockGrammarRepository.searchGrammars(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(
          () => mockGrammarRepository.searchGrammars(
            query: tQuery,
            limit: tLimit,
            offset: tOffset,
          ),
        );
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  // Params tests
  group('GetGrammarParams', () {
    test('should create GetGrammarParams with correct values', () {
      // arrange
      const tId = 1;

      // act
      const params = GetGrammarParams(id: tId);

      // assert
      expect(params.id, tId);
    });
  });

  group('GetGrammarsParams', () {
    test('should create GetGrammarsParams with correct values', () {
      // arrange
      const tLimit = 10;
      const tOffset = 0;

      // act
      const params = GetGrammarsParams(limit: tLimit, offset: tOffset);

      // assert
      expect(params.limit, tLimit);
      expect(params.offset, tOffset);
    });
  });

  group('GetGrammarsByLevelParams', () {
    test('should create GetGrammarsByLevelParams with correct values', () {
      // arrange
      const tLevel = 2;
      const tLimit = 10;
      const tOffset = 0;

      // act
      const params = GetGrammarsByLevelParams(
        level: tLevel,
        limit: tLimit,
        offset: tOffset,
      );

      // assert
      expect(params.level, tLevel);
      expect(params.limit, tLimit);
      expect(params.offset, tOffset);
    });
  });

  group('GetGrammarsByTagParams', () {
    test('should create GetGrammarsByTagParams with correct values', () {
      // arrange
      const tTag = 1;
      const tLimit = 10;
      const tOffset = 0;

      // act
      const params = GetGrammarsByTagParams(
        tag: tTag,
        limit: tLimit,
        offset: tOffset,
      );

      // assert
      expect(params.tag, tTag);
      expect(params.limit, tLimit);
      expect(params.offset, tOffset);
    });
  });

  group('SearchGrammarsParams', () {
    test('should create SearchGrammarsParams with correct values', () {
      // arrange
      const tQuery = 'present';
      const tLimit = 10;
      const tOffset = 0;

      // act
      const params = SearchGrammarsParams(
        query: tQuery,
        limit: tLimit,
        offset: tOffset,
      );

      // assert
      expect(params.query, tQuery);
      expect(params.limit, tLimit);
      expect(params.offset, tOffset);
    });
  });
}
