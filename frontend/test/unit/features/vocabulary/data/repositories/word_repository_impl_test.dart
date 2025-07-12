import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/data/data_sources/word_remote_datasources.dart';
import 'package:learn/features/vocabulary/data/models/word_model.dart';
import 'package:learn/features/vocabulary/data/repositories/word_repository_impl.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/repositories/word_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockWordRemoteDataSource extends Mock implements WordRemoteDataSource {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late WordRepository repository;
  late MockWordRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockRemoteDataSource = MockWordRemoteDataSource();
    repository = WordRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('WordRepositoryImpl', () {
    const tWordModel = WordModel(
      id: 1,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
    );

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

    const tWordsList = [tWordModel];
    const tWordsEntity = [tWord];

    group('getAllWords', () {
      const tOffset = 0;
      const tLimit = 10;

      test(
        'should return server failure',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getWords(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(),
              ),
            ),
          );

          // act
          final result = await repository.getAllWords(
            offset: tOffset,
            limit: tLimit,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getWords(
              offset: tOffset,
              limit: tLimit,
            ),
          );
          expect(result, isA<Left<Failure, List<Word>>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('Words not found'),
            ),
          );
        },
      );

      test(
        'should return server failure when a 500 error occurs',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getWords(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(),
              ),
            ),
          );

          // act
          final result = await repository.getAllWords(
            offset: tOffset,
            limit: tLimit,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getWords(
              offset: tOffset,
              limit: tLimit,
            ),
          );
          expect(result, isA<Left<Failure, List<Word>>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('Server error'),
            ),
          );
        },
      );

      test(
        'should return network failure when a network error occurs',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getWords(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.connectionTimeout,
            ),
          );

          // act
          final result = await repository.getAllWords(
            offset: tOffset,
            limit: tLimit,
          );

          // assert
          verify(
            () => mockRemoteDataSource.getWords(
              offset: tOffset,
              limit: tLimit,
            ),
          );
          expect(result, isA<Left<Failure, List<Word>>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('An unexpected error occurred'),
            ),
          );
        },
      );
    });

    group('getWordById', () {
      const tWordId = 1;

      test(
        'should return word when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getWord(any()),
          ).thenAnswer((_) async => tWordModel);

          // act
          final result = await repository.getWordById(id: tWordId);

          // assert
          verify(() => mockRemoteDataSource.getWord(tWordId));
          expect(result, equals(const Right<Failure, Word>(tWord)));
        },
      );

      test(
        'should return server failure when word is not found',
        () async {
          // arrange
          when(() => mockRemoteDataSource.getWord(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(),
              ),
            ),
          );

          // act
          final result = await repository.getWordById(id: tWordId);

          // assert
          verify(() => mockRemoteDataSource.getWord(tWordId));
          expect(result, isA<Left<Failure, Word>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('Word not found'),
            ),
          );
        },
      );

      test(
        'should return server failure when a 500 error occurs',
        () async {
          // arrange
          when(() => mockRemoteDataSource.getWord(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(),
              ),
            ),
          );

          // act
          final result = await repository.getWordById(id: tWordId);

          // assert
          verify(() => mockRemoteDataSource.getWord(tWordId));
          expect(result, isA<Left<Failure, Word>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('Server error'),
            ),
          );
        },
      );

      test(
        'should return network failure when a network error occurs',
        () async {
          // arrange
          when(() => mockRemoteDataSource.getWord(any())).thenThrow(
            DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.connectionTimeout,
            ),
          );

          // act
          final result = await repository.getWordById(id: tWordId);

          // assert
          verify(() => mockRemoteDataSource.getWord(tWordId));
          expect(result, isA<Left<Failure, Word>>());
          expect(
            (result as Left).value,
            isA<Failure>().having(
              (final f) => f.message,
              'message',
              contains('An unexpected error occurred'),
            ),
          );
        },
      );
    });
  });
}
