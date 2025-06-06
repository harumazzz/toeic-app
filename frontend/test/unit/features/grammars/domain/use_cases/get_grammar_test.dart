import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/core/use_cases/use_case.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/repositories/grammar_repository.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammar.dart';
import 'package:mocktail/mocktail.dart';

class MockGrammarRepository extends Mock implements GrammarRepository {}

void main() {
  late GetGrammar getGrammarUseCase;
  late GetRandomGrammar getRandomGrammarUseCase;
  late MockGrammarRepository mockGrammarRepository;

  setUp(() {
    mockGrammarRepository = MockGrammarRepository();
    getGrammarUseCase = GetGrammar(mockGrammarRepository);
    getRandomGrammarUseCase = GetRandomGrammar(mockGrammarRepository);
  });

  group('GetGrammar', () {
    const tId = 1;
    const tParams = GetGrammarParams(id: tId);
    const tGrammar = Grammar(
      id: tId,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    );

    test(
      'should get grammar from repository by ID when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getGrammarById(id: any(named: 'id')),
        ).thenAnswer((_) async => const Right(tGrammar));

        // act
        final result = await getGrammarUseCase(tParams);

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
        final result = await getGrammarUseCase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockGrammarRepository.getGrammarById(id: tId));
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });

  group('GetRandomGrammar', () {
    const tGrammar = Grammar(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    );
    const tParams = NoParams();

    test(
      'should get a random grammar from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockGrammarRepository.getRandomGrammar(),
        ).thenAnswer((_) async => const Right(tGrammar));

        // act
        final result = await getRandomGrammarUseCase(tParams);

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
        final result = await getRandomGrammarUseCase(tParams);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockGrammarRepository.getRandomGrammar());
        verifyNoMoreInteractions(mockGrammarRepository);
      },
    );
  });
}
