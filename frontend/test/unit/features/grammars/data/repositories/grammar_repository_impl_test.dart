import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/grammars/data/data_sources/grammar_remote_data_source.dart';
import 'package:learn/features/grammars/data/models/grammar_model.dart';
import 'package:learn/features/grammars/data/repositories/grammar_repository_impl.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/repositories/grammar_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockGrammarRemoteDataSource extends Mock
    implements GrammarRemoteDataSource {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeGetRelatedGrammarsRequest extends Fake
    implements GetRelatedGrammarsRequest {}

void main() {
  late GrammarRepository repository;
  late MockGrammarRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeGetRelatedGrammarsRequest());
  });

  setUp(() {
    mockRemoteDataSource = MockGrammarRemoteDataSource();
    repository = GrammarRepositoryImpl(
      grammarRemoteDataSource: mockRemoteDataSource,
    );
  });

  group('GrammarRepositoryImpl', () {
    const tGrammarModel = GrammarModel(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
      contents: [],
    );

    const tGrammar = Grammar(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
      contents: [],
    );

    const tGrammarModels = [tGrammarModel];
    const tGrammars = [tGrammar];

    group('getAllGrammars', () {
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should return List<Grammar>',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getAllGrammars(
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => tGrammarModels);

          // act
          final result = await repository.getAllGrammars(
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getAllGrammars(
              limit: tLimit,
              offset: tOffset,
            ),
          );
          expect(
            result.toString(),
            Right<Failure, List<Grammar>>(tGrammars).toString(),
          );
        },
      );
    });

    group('getAllGrammarsByLevel', () {
      const tLevel = 1;
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should return List<Grammar> when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getAllGrammarsByLevel(
              level: any(named: 'level'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => tGrammarModels);

          // act
          final result = await repository.getAllGrammarsByLevel(
            level: tLevel,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getAllGrammarsByLevel(
              level: tLevel,
              limit: tLimit,
              offset: tOffset,
            ),
          );
          expect(
            result.toString(),
            Right<Failure, List<Grammar>>(tGrammars).toString(),
          );
        },
      );
    });

    group('getAllGrammarsByTag', () {
      const tTag = 1;
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should return List<Grammar> when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getAllGrammarsByTag(
              tag: any(named: 'tag'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => tGrammarModels);

          // act
          final result = await repository.getAllGrammarsByTag(
            tag: tTag,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getAllGrammarsByTag(
              tag: tTag.toString(),
              limit: tLimit,
              offset: tOffset,
            ),
          );
          expect(
            result.toString(),
            Right<Failure, List<Grammar>>(tGrammars).toString(),
          );
        },
      );
    });

    group('getGrammarById', () {
      const tId = 1;

      test(
        'should return Grammar when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getGrammarById(
              id: any(named: 'id'),
            ),
          ).thenAnswer((_) async => tGrammarModel);

          // act
          final result = await repository.getGrammarById(id: tId);

          // assert
          verify(() => mockRemoteDataSource.getGrammarById(id: tId));
          expect(
            result.toString(),
            Right<Failure, Grammar>(tGrammar).toString(),
          );
        },
      );
    });

    group('getRandomGrammar', () {
      test(
        'should return Grammar when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getRandomGrammar(),
          ).thenAnswer((_) async => tGrammarModel);

          // act
          final result = await repository.getRandomGrammar();

          // assert
          verify(() => mockRemoteDataSource.getRandomGrammar());
          expect(
            result.toString(),
            Right<Failure, Grammar>(tGrammar).toString(),
          );
        },
      );
    });

    group('searchGrammars', () {
      const tQuery = 'present';
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should return List<Grammar> when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.searchGrammars(
              query: any(named: 'query'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => tGrammarModels);

          // act
          final result = await repository.searchGrammars(
            query: tQuery,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockRemoteDataSource.searchGrammars(
              query: tQuery,
              limit: tLimit,
              offset: tOffset,
            ),
          );
          expect(
            result.toString(),
            Right<Failure, List<Grammar>>(tGrammars).toString(),
          );
        },
      );
    });

    group('getRelatedGrammars', () {
      const tIds = [1, 2, 3];

      test(
        'should return List<Grammar>',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getRelatedGrammars(
              ids: any(named: 'ids'),
            ),
          ).thenAnswer((_) async => tGrammarModels);

          // act
          final result = await repository.getRelatedGrammars(ids: tIds);

          // assert
          verify(
            () => mockRemoteDataSource.getRelatedGrammars(
              ids: any(named: 'ids'),
            ),
          );
          expect(
            result.toString(),
            Right<Failure, List<Grammar>>(tGrammars).toString(),
          );
        },
      );
    });
  });
}
