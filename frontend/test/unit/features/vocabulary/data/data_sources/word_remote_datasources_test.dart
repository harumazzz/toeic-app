import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/data/data_sources/word_remote_datasources.dart';
import 'package:learn/features/vocabulary/data/models/word_model.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late WordRemoteDataSource dataSource;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });
  
  setUp(() {
    mockDio = MockDio();
    
    // Mock the options property required by Retrofit
    when(() => mockDio.options).thenReturn(BaseOptions());
    
    dataSource = WordRemoteDataSource(mockDio);
  });

  group('WordRemoteDataSource', () {
    const tWordModel = WordModel(
      id: 1,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
    );

    const tWordsList = [tWordModel];
    const tOffset = 0;
    const tLimit = 10;
    const tWordId = 1;

    group('getWords', () {      test('should perform GET request to correct endpoint', () async {
        // arrange
        when(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<List<dynamic>>(
            data: [tWordModel.toJson()],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words'),
          ),
        );

        // act
        await dataSource.getWords(offset: tOffset, limit: tLimit);

        // assert
        verify(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).called(1);
      });      test('should return List<WordModel> when call is successful', () async {
        // arrange
        when(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<List<dynamic>>(
            data: [tWordModel.toJson()],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words'),
          ),
        );

        // act
        final result = await dataSource.getWords(
          offset: tOffset,
          limit: tLimit,
        );

        // assert
        expect(result, tWordsList);
      });      test('should handle empty response correctly', () async {
        // arrange
        when(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<List<dynamic>>(
            data: [],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words'),
          ),
        );

        // act
        final result = await dataSource.getWords(
          offset: tOffset,
          limit: tLimit,
        );

        // assert
        expect(result, isEmpty);
      });      test('should handle default parameters', () async {
        // arrange
        when(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<List<dynamic>>(
            data: [tWordModel.toJson()],
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words'),
          ),
        );

        // act
        await dataSource.getWords();

        // assert
        verify(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).called(1);
      });      test('should throw DioException when request fails', () async {
        // arrange
        when(
          () => mockDio.fetch<List<dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/words'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/words'),
            ),
          ),
        );

        // act & assert
        expect(
          () => dataSource.getWords(offset: tOffset, limit: tLimit),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getWord', () {      test('should perform GET request to correct endpoint with id', () async {
        // arrange
        when(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: tWordModel.toJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
          ),
        );

        // act
        await dataSource.getWord(tWordId);

        // assert
        verify(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).called(1);
      });      test('should return WordModel when call is successful', () async {
        // arrange
        when(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: tWordModel.toJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
          ),
        );

        // act
        final result = await dataSource.getWord(tWordId);

        // assert
        expect(result, tWordModel);
      });      test('should throw DioException when word not found', () async {
        // arrange
        when(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
            ),
          ),
        );

        // act & assert
        expect(
          () => dataSource.getWord(tWordId),
          throwsA(isA<DioException>()),
        );
      });      test('should throw DioException when server error occurs', () async {
        // arrange
        when(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
            ),
          ),
        );

        // act & assert
        expect(
          () => dataSource.getWord(tWordId),
          throwsA(isA<DioException>()),
        );
      });      test('should handle network error', () async {
        // arrange
        when(
          () => mockDio.fetch<Map<String, dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/words/$tWordId'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // act & assert
        expect(
          () => dataSource.getWord(tWordId),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
