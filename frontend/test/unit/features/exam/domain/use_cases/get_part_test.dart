import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/practice/domain/entities/part.dart';
import 'package:learn/features/practice/domain/repositories/part_repository.dart';
import 'package:learn/features/practice/domain/use_cases/get_part.dart';
import 'package:mocktail/mocktail.dart';

class MockPartRepository extends Mock implements PartRepository {}

void main() {
  late MockPartRepository mockRepository;
  late GetPart getPart;
  late GetPartsByExam getPartsByExam;

  setUp(() {
    mockRepository = MockPartRepository();
    getPart = GetPart(mockRepository);
    getPartsByExam = GetPartsByExam(mockRepository);
  });

  group('GetPart', () {
    const testPart = Part(
      examId: 1,
      partId: 1,
      title: 'Part 1: Photographs',
    );

    test('should get part by id successfully', () async {
      // arrange
      when(
        () => mockRepository.getPartById(partId: 1),
      ).thenAnswer((_) async => const Right(testPart));

      // act
      final result = await getPart(const GetPartParams(partId: 1));

      // assert
      expect(result, const Right(testPart));
      verify(() => mockRepository.getPartById(partId: 1)).called(1);
    });

    test('should return failure when getting part fails', () async {
      // arrange
      when(
        () => mockRepository.getPartById(partId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getPart(const GetPartParams(partId: 1));

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getPartById(partId: 1)).called(1);
    });
  });

  group('GetPartsByExam', () {
    const testParts = [
      Part(
        examId: 1,
        partId: 1,
        title: 'Part 1: Photographs',
      ),
      Part(
        examId: 1,
        partId: 2,
        title: 'Part 2: Question-Response',
      ),
    ];

    test('should get parts by exam id successfully', () async {
      // arrange
      when(
        () => mockRepository.getPartsByExamId(examId: 1),
      ).thenAnswer((_) async => const Right(testParts));

      // act
      final result = await getPartsByExam(
        const GetPartsByExamParams(examId: 1),
      );

      // assert
      expect(result, const Right(testParts));
      verify(() => mockRepository.getPartsByExamId(examId: 1)).called(1);
    });

    test('should return failure when getting parts fails', () async {
      // arrange
      when(
        () => mockRepository.getPartsByExamId(examId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      // act
      final result = await getPartsByExam(
        const GetPartsByExamParams(examId: 1),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getPartsByExamId(examId: 1)).called(1);
    });
  });
}
