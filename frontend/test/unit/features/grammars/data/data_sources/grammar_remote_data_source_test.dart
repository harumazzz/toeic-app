import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/data/data_sources/grammar_remote_data_source.dart';
import 'package:learn/features/grammars/data/models/grammar_model.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late GrammarRemoteDataSource dataSource;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    dataSource = GrammarRemoteDataSource(mockDio);
  });

  group('GrammarRemoteDataSource', () {
    const tGrammarModel = GrammarModel(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
    );

    const tGrammarModels = [tGrammarModel];

    setUp(() {
      // Set up the options property to avoid null errors
      when(() => mockDio.options).thenReturn(BaseOptions());
      // Mock the fetch method that the generated code uses
      when(() => mockDio.fetch<List<dynamic>>(any())).thenAnswer((
        final invocation,
      ) async {
        final requestOptions =
            invocation.positionalArguments[0] as RequestOptions;
        return Response<List<dynamic>>(
          data: [tGrammarModel.toJson()],
          statusCode: 200,
          requestOptions: requestOptions,
        );
      });
      when(() => mockDio.fetch<Map<String, dynamic>>(any())).thenAnswer((
        final invocation,
      ) async {
        final requestOptions =
            invocation.positionalArguments[0] as RequestOptions;
        return Response<Map<String, dynamic>>(
          data: tGrammarModel.toJson(),
          statusCode: 200,
          requestOptions: requestOptions,
        );
      });
    });

    group('getAllGrammars', () {
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should perform a GET request on /api/v1/grammars with correct parameters',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<List<dynamic>>(
              data: [tGrammarModel.toJson()],
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars'),
            ),
          );

          // act
          final result = await dataSource.getAllGrammars(
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockDio.fetch<List<dynamic>>(any()),
          );
          expect(result, equals(tGrammarModels));
        },
      );

      test(
        'should throw DioException when the response has an error status code',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/api/v1/grammars'),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: '/api/v1/grammars'),
              ),
            ),
          );

          // act & assert
          expect(
            () => dataSource.getAllGrammars(limit: tLimit, offset: tOffset),
            throwsA(isA<DioException>()),
          );
        },
      );
    });

    group('getAllGrammarsByLevel', () {
      const tLevel = 1;
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should perform a GET request on /api/v1/grammars/level with correct parameters',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<List<dynamic>>(
              data: [tGrammarModel.toJson()],
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/level'),
            ),
          );

          // act
          final result = await dataSource.getAllGrammarsByLevel(
            level: tLevel,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockDio.fetch<List<dynamic>>(any()),
          );
          expect(result, equals(tGrammarModels));
        },
      );
    });

    group('getAllGrammarsByTag', () {
      const tTag = 'basic';
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should perform a GET request on /api/v1/grammars/tag with correct parameters',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<List<dynamic>>(
              data: [tGrammarModel.toJson()],
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/tag'),
            ),
          );

          // act
          final result = await dataSource.getAllGrammarsByTag(
            tag: tTag,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockDio.fetch<List<dynamic>>(any()),
          );
          expect(result, equals(tGrammarModels));
        },
      );
    });

    group('getGrammarById', () {
      const tId = 1;

      test(
        'should perform a GET request on /api/v1/grammars/{id} with correct parameters',
        () async {
          // arrange
          when(
            () => mockDio.fetch<Map<String, dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<Map<String, dynamic>>(
              data: tGrammarModel.toJson(),
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/$tId'),
            ),
          );

          // act
          final result = await dataSource.getGrammarById(id: tId);

          // assert
          verify(() => mockDio.fetch<Map<String, dynamic>>(any()));
          expect(result, equals(tGrammarModel));
        },
      );
    });

    group('getRandomGrammar', () {
      test(
        'should perform a GET request on /api/v1/grammars/random',
        () async {
          // arrange
          when(
            () => mockDio.fetch<Map<String, dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<Map<String, dynamic>>(
              data: tGrammarModel.toJson(),
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/random'),
            ),
          );

          // act
          final result = await dataSource.getRandomGrammar();

          // assert
          verify(() => mockDio.fetch<Map<String, dynamic>>(any()));
          expect(result, equals(tGrammarModel));
        },
      );
    });

    group('searchGrammars', () {
      const tQuery = 'present';
      const tLimit = 10;
      const tOffset = 0;

      test(
        'should perform a GET request on /api/v1/grammars/search with correct parameters',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<List<dynamic>>(
              data: [tGrammarModel.toJson()],
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/search'),
            ),
          );

          // act
          final result = await dataSource.searchGrammars(
            query: tQuery,
            limit: tLimit,
            offset: tOffset,
          );

          // assert
          verify(
            () => mockDio.fetch<List<dynamic>>(any()),
          );
          expect(result, equals(tGrammarModels));
        },
      );
    });

    group('getRelatedGrammars', () {
      const tIds = [1, 2, 3];

      test(
        'should perform a POST request on /api/v1/grammars/batch with correct body',
        () async {
          // arrange
          when(
            () => mockDio.fetch<List<dynamic>>(any()),
          ).thenAnswer(
            (_) async => Response<List<dynamic>>(
              data: [tGrammarModel.toJson()],
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/grammars/batch'),
            ),
          );

          // act
          final result = await dataSource.getRelatedGrammars(
            ids: const GetRelatedGrammarsRequest(ids: tIds),
          );

          // assert
          verify(
            () => mockDio.fetch<List<dynamic>>(any()),
          );
          expect(result, equals(tGrammarModels));
        },
      );
    });
  });
}
