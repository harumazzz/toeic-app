import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/repositories/grammar_repository.dart';
import 'package:learn/features/grammars/domain/use_cases/search_grammar.dart';
import 'package:mocktail/mocktail.dart';

class MockGrammarRepository extends Mock implements GrammarRepository {}

void main() {
  late SearchGrammar usecase;
  late MockGrammarRepository mockGrammarRepository;

  setUp(() {
    mockGrammarRepository = MockGrammarRepository();
    usecase = SearchGrammar(mockGrammarRepository);
  });

  group('SearchGrammar', () {
    const tQuery = 'present';
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
        title: 'Present Continuous',
        grammarKey: 'present_continuous',
        level: 2,
      ),
    ];
    const tParams = SearchGrammarsParams(
      query: tQuery,
      limit: tLimit,
      offset: tOffset,
    );

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

  group('SearchGrammarsParams', () {
    test('should create SearchGrammarsParams with correct values', () {
      // arrange
      const query = 'present';
      const limit = 10;
      const offset = 0;

      // act
      const params = SearchGrammarsParams(
        query: query,
        limit: limit,
        offset: offset,
      );

      // assert
      expect(params.query, query);
      expect(params.limit, limit);
      expect(params.offset, offset);
    });

    test('should support equality comparison', () {
      // arrange
      const params1 = SearchGrammarsParams(
        query: 'present',
        limit: 10,
        offset: 0,
      );

      const params2 = SearchGrammarsParams(
        query: 'present',
        limit: 10,
        offset: 0,
      );

      const params3 = SearchGrammarsParams(
        query: 'different',
        limit: 10,
        offset: 0,
      );

      // assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });
  });
}
