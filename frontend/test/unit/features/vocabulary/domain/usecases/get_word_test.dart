import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/domain/repositories/word_repository.dart';
import 'package:learn/features/vocabulary/domain/use_cases/get_word.dart';
import 'package:mocktail/mocktail.dart';

class MockWordRepository extends Mock implements WordRepository {}

void main() {
  late GetWord usecase;
  late MockWordRepository mockWordRepository;

  setUp(() {
    mockWordRepository = MockWordRepository();
    usecase = GetWord(mockWordRepository);
  });

  group('GetWord Use Case', () {
    const tWordId = 1;
    const tWord = Word(
      id: tWordId,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
      means: [],
      snym: [],
    );
    const tParams = GetWordParams(id: tWordId);

    test(
      'should get word from the repository when call is successful',
      () async {
        // arrange
        when(
          () => mockWordRepository.getWordById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(tWord));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tWord));
        verify(() => mockWordRepository.getWordById(id: tWordId));
        verifyNoMoreInteractions(mockWordRepository);
      },
    );

    test('should return failure when repository call fails', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Word not found',
      );
      when(
        () => mockWordRepository.getWordById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockWordRepository.getWordById(id: tWordId));
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(message: 'Network error');
      when(
        () => mockWordRepository.getWordById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockWordRepository.getWordById(id: tWordId));
      verifyNoMoreInteractions(mockWordRepository);
    });

    test('should return server failure when server error occurs', () async {
      // arrange
      const tFailure = Failure.serverFailure(message: 'Server error');
      when(
        () => mockWordRepository.getWordById(id: any(named: 'id')),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockWordRepository.getWordById(id: tWordId));
      verifyNoMoreInteractions(mockWordRepository);
    });
  });

  group('GetWordParams', () {
    test('should create GetWordParams with correct values', () {
      // arrange
      const tId = 1;

      // act
      const params = GetWordParams(id: tId);

      // assert
      expect(params.id, tId);
    });

    test('should support equality comparison', () {
      // arrange
      const tId = 1;

      // act
      const params1 = GetWordParams(id: tId);
      const params2 = GetWordParams(id: tId);

      // assert
      expect(params1, params2);
      expect(params1.hashCode, params2.hashCode);
    });

    test('should not be equal with different ids', () {
      // arrange
      const params1 = GetWordParams(id: 1);
      const params2 = GetWordParams(id: 2);

      // assert
      expect(params1, isNot(params2));
      expect(params1.hashCode, isNot(params2.hashCode));
    });
  });
}
