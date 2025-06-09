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
  late MockGrammarRepository mockRepository;
  late GetGrammar getGrammar;
  late GetRandomGrammar getRandomGrammar;
  late GetGrammars getGrammars;
  late GetGrammarsByLevel getGrammarsByLevel;
  late GetGrammarsByTag getGrammarsByTag;
  late GetRelatedGrammars getRelatedGrammars;
  late SearchGrammar searchGrammar;

  setUp(() {
    mockRepository = MockGrammarRepository();
    getGrammar = GetGrammar(mockRepository);
    getRandomGrammar = GetRandomGrammar(mockRepository);
    getGrammars = GetGrammars(mockRepository);
    getGrammarsByLevel = GetGrammarsByLevel(mockRepository);
    getGrammarsByTag = GetGrammarsByTag(mockRepository);
    getRelatedGrammars = GetRelatedGrammars(mockRepository);
    searchGrammar = SearchGrammar(mockRepository);
  });

  group('GetGrammar Use Case', () {
    const testGrammar = Grammar(
      id: 1,
      grammarKey: 'present_simple',
      level: 1,
      title: 'Present Simple',
    );

    test('should get grammar by id successfully', () async {
      when(
        () => mockRepository.getGrammarById(id: 1),
      ).thenAnswer((_) async => const Right(testGrammar));

      final result = await getGrammar(const GetGrammarParams(id: 1));

      expect(result, const Right(testGrammar));
      verify(() => mockRepository.getGrammarById(id: 1)).called(1);
    });

    test('should return failure when getting grammar fails', () async {
      when(
        () => mockRepository.getGrammarById(id: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getGrammar(const GetGrammarParams(id: 1));

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getGrammarById(id: 1)).called(1);
    });
  });

  group('GetRandomGrammar Use Case', () {
    const testGrammar = Grammar(
      id: 1,
      grammarKey: 'present_simple',
      level: 1,
      title: 'Present Simple',
    );

    test('should get random grammar successfully', () async {
      when(
        () => mockRepository.getRandomGrammar(),
      ).thenAnswer((_) async => const Right(testGrammar));

      final result = await getRandomGrammar(const NoParams());

      expect(result, const Right(testGrammar));
      verify(() => mockRepository.getRandomGrammar()).called(1);
    });

    test('should return failure when getting random grammar fails', () async {
      when(
        () => mockRepository.getRandomGrammar(),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getRandomGrammar(const NoParams());

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getRandomGrammar()).called(1);
    });
  });

  group('GetGrammars Use Case', () {
    const testGrammars = [
      Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      ),
      Grammar(
        id: 2,
        grammarKey: 'present_continuous',
        level: 1,
        title: 'Present Continuous',
      ),
    ];

    test('should get all grammars successfully', () async {
      when(
        () => mockRepository.getAllGrammars(limit: 10, offset: 0),
      ).thenAnswer((_) async => const Right(testGrammars));

      final result = await getGrammars(
        const GetGrammarsParams(limit: 10, offset: 0),
      );

      expect(result, const Right(testGrammars));
      verify(
        () => mockRepository.getAllGrammars(limit: 10, offset: 0),
      ).called(1);
    });

    test('should return failure when getting all grammars fails', () async {
      when(
        () => mockRepository.getAllGrammars(limit: 10, offset: 0),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getGrammars(
        const GetGrammarsParams(limit: 10, offset: 0),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockRepository.getAllGrammars(limit: 10, offset: 0),
      ).called(1);
    });
  });

  group('GetGrammarsByLevel Use Case', () {
    const testGrammars = [
      Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      ),
      Grammar(
        id: 2,
        grammarKey: 'present_continuous',
        level: 1,
        title: 'Present Continuous',
      ),
    ];

    test('should get grammars by level successfully', () async {
      when(
        () => mockRepository.getAllGrammarsByLevel(
          level: 1,
          limit: 10,
          offset: 0,
        ),
      ).thenAnswer((_) async => const Right(testGrammars));

      final result = await getGrammarsByLevel(
        const GetGrammarsByLevelParams(level: 1, limit: 10, offset: 0),
      );

      expect(result, const Right(testGrammars));
      verify(
        () => mockRepository.getAllGrammarsByLevel(
          level: 1,
          limit: 10,
          offset: 0,
        ),
      ).called(1);
    });

    test(
      'should return failure when getting grammars by level fails',
      () async {
        when(
          () => mockRepository.getAllGrammarsByLevel(
            level: 1,
            limit: 10,
            offset: 0,
          ),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

        final result = await getGrammarsByLevel(
          const GetGrammarsByLevelParams(level: 1, limit: 10, offset: 0),
        );

        expect(result, const Left(ServerFailure(message: 'Error')));
        verify(
          () => mockRepository.getAllGrammarsByLevel(
            level: 1,
            limit: 10,
            offset: 0,
          ),
        ).called(1);
      },
    );
  });

  group('GetGrammarsByTag Use Case', () {
    const testGrammars = [
      Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      ),
      Grammar(
        id: 2,
        grammarKey: 'present_continuous',
        level: 1,
        title: 'Present Continuous',
      ),
    ];

    test('should get grammars by tag successfully', () async {
      when(
        () => mockRepository.getAllGrammarsByTag(
          tag: 1,
          limit: 10,
          offset: 0,
        ),
      ).thenAnswer((_) async => const Right(testGrammars));

      final result = await getGrammarsByTag(
        const GetGrammarsByTagParams(tag: 1, limit: 10, offset: 0),
      );

      expect(result, const Right(testGrammars));
      verify(
        () => mockRepository.getAllGrammarsByTag(
          tag: 1,
          limit: 10,
          offset: 0,
        ),
      ).called(1);
    });

    test('should return failure when getting grammars by tag fails', () async {
      when(
        () => mockRepository.getAllGrammarsByTag(
          tag: 1,
          limit: 10,
          offset: 0,
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getGrammarsByTag(
        const GetGrammarsByTagParams(tag: 1, limit: 10, offset: 0),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockRepository.getAllGrammarsByTag(
          tag: 1,
          limit: 10,
          offset: 0,
        ),
      ).called(1);
    });
  });

  group('GetRelatedGrammars Use Case', () {
    const testGrammars = [
      Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      ),
      Grammar(
        id: 2,
        grammarKey: 'present_continuous',
        level: 1,
        title: 'Present Continuous',
      ),
    ];

    test('should get related grammars successfully', () async {
      when(
        () => mockRepository.getRelatedGrammars(ids: [1, 2]),
      ).thenAnswer((_) async => const Right(testGrammars));

      final result = await getRelatedGrammars(
        const GetRelatedGrammarsParams(ids: [1, 2]),
      );

      expect(result, const Right(testGrammars));
      verify(() => mockRepository.getRelatedGrammars(ids: [1, 2])).called(1);
    });

    test('should return failure when getting related grammars fails', () async {
      when(
        () => mockRepository.getRelatedGrammars(ids: [1, 2]),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getRelatedGrammars(
        const GetRelatedGrammarsParams(ids: [1, 2]),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getRelatedGrammars(ids: [1, 2])).called(1);
    });
  });

  group('SearchGrammar Use Case', () {
    const testGrammars = [
      Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      ),
      Grammar(
        id: 2,
        grammarKey: 'present_continuous',
        level: 1,
        title: 'Present Continuous',
      ),
    ];

    test('should search grammars successfully', () async {
      when(
        () => mockRepository.searchGrammars(
          query: 'present',
          limit: 10,
          offset: 0,
        ),
      ).thenAnswer((_) async => const Right(testGrammars));

      final result = await searchGrammar(
        const SearchGrammarsParams(query: 'present', limit: 10, offset: 0),
      );

      expect(result, const Right(testGrammars));
      verify(
        () => mockRepository.searchGrammars(
          query: 'present',
          limit: 10,
          offset: 0,
        ),
      ).called(1);
    });

    test('should return failure when searching grammars fails', () async {
      when(
        () => mockRepository.searchGrammars(
          query: 'present',
          limit: 10,
          offset: 0,
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await searchGrammar(
        const SearchGrammarsParams(query: 'present', limit: 10, offset: 0),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockRepository.searchGrammars(
          query: 'present',
          limit: 10,
          offset: 0,
        ),
      ).called(1);
    });
  });
}
