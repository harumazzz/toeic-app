import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/progress/domain/entities/progress.dart';
import 'package:learn/features/progress/domain/repositories/progress_repository.dart';
import 'package:learn/features/progress/domain/use_cases/add_progress.dart';
import 'package:learn/features/progress/domain/use_cases/delete_progress.dart';
import 'package:learn/features/progress/domain/use_cases/get_progress.dart';
import 'package:learn/features/progress/domain/use_cases/update_progress.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:mocktail/mocktail.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late MockProgressRepository mockRepository;
  late AddProgress addProgress;
  late UpdateProgress updateProgress;
  late GetReviewsProgress getReviewsProgress;
  late GetWorkProgress getWorkProgress;
  late GetProgress getProgress;
  late DeleteProgress deleteProgress;

  final testDateTime = DateTime(2024);

  setUp(() {
    mockRepository = MockProgressRepository();
    addProgress = AddProgress(mockRepository);
    updateProgress = UpdateProgress(mockRepository);
    getReviewsProgress = GetReviewsProgress(mockRepository);
    getWorkProgress = GetWorkProgress(mockRepository);
    getProgress = GetProgress(mockRepository);
    deleteProgress = DeleteProgress(mockRepository);
  });

  group('AddProgress Use Case', () {
    final request = WordProgressRequest(
      easeFactor: 2,
      intervalDays: 1,
      lastReviewedAt: DateTime(2024),
      nextReviewAt: DateTime(2024, 1, 2),
      repetitions: 0,
      wordId: 1,
    );

    const word = Word(
      id: 1,
      word: 'test',
      descriptLevel: 'A1',
      freq: 100,
      level: 1,
      pronounce: '/test/',
      shortMean: 'test meaning',
    );

    final progress = Progress(
      createdAt: testDateTime,
      easeFactor: 2,
      intervalDays: 1,
      lastReviewedAt: DateTime(2024),
      nextReviewAt: DateTime(2024, 1, 2),
      repetitions: 0,
      updatedAt: testDateTime,
      userId: 1,
      wordId: 1,
    );

    final wordProgress = WordProgress(
      progress: progress,
      word: word,
    );

    test('should add new progress successfully', () async {
      when(
        () => mockRepository.addNewProgress(request: request),
      ).thenAnswer((_) async => Right(wordProgress));

      final result = await addProgress(
        AddProgressParams(request: request),
      );

      expect(result, Right(wordProgress));
      verify(() => mockRepository.addNewProgress(request: request)).called(1);
    });

    test('should return failure when adding progress fails', () async {
      when(
        () => mockRepository.addNewProgress(request: request),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await addProgress(
        AddProgressParams(request: request),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.addNewProgress(request: request)).called(1);
    });
  });

  group('UpdateProgress Use Case', () {
    final request = WordProgressRequest(
      easeFactor: 2,
      intervalDays: 1,
      lastReviewedAt: DateTime(2024),
      nextReviewAt: DateTime(2024, 1, 2),
      repetitions: 0,
      wordId: 1,
    );

    const word = Word(
      id: 1,
      word: 'test',
      descriptLevel: 'A1',
      freq: 100,
      level: 1,
      pronounce: '/test/',
      shortMean: 'test meaning',
    );

    final progress = Progress(
      createdAt: testDateTime,
      easeFactor: 2,
      intervalDays: 1,
      lastReviewedAt: DateTime(2024),
      nextReviewAt: DateTime(2024, 1, 2),
      repetitions: 0,
      updatedAt: testDateTime,
      userId: 1,
      wordId: 1,
    );

    final wordProgress = WordProgress(
      progress: progress,
      word: word,
    );

    test('should update progress successfully', () async {
      when(
        () => mockRepository.updateProgress(
          wordId: 1,
          request: request,
        ),
      ).thenAnswer((_) async => Right(wordProgress));

      final result = await updateProgress(
        UpdateProgressParams(
          wordId: 1,
          request: request,
        ),
      );

      expect(result, Right(wordProgress));
      verify(
        () => mockRepository.updateProgress(
          wordId: 1,
          request: request,
        ),
      ).called(1);
    });

    test('should return failure when updating progress fails', () async {
      when(
        () => mockRepository.updateProgress(
          wordId: 1,
          request: request,
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await updateProgress(
        UpdateProgressParams(
          wordId: 1,
          request: request,
        ),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(
        () => mockRepository.updateProgress(
          wordId: 1,
          request: request,
        ),
      ).called(1);
    });
  });

  group('GetProgress Use Cases', () {
    const word = Word(
      id: 1,
      word: 'test',
      descriptLevel: 'A1',
      freq: 100,
      level: 1,
      pronounce: '/test/',
      shortMean: 'test meaning',
    );

    final progress = Progress(
      createdAt: testDateTime,
      easeFactor: 2,
      intervalDays: 1,
      lastReviewedAt: DateTime(2024),
      nextReviewAt: DateTime(2024, 1, 2),
      repetitions: 0,
      updatedAt: testDateTime,
      userId: 1,
      wordId: 1,
    );

    final wordProgress = WordProgress(
      progress: progress,
      word: word,
    );

    test('should get reviews progress successfully', () async {
      when(
        () => mockRepository.getReviewsProgress(limit: 10),
      ).thenAnswer((_) async => Right([wordProgress]));

      final _ = await getReviewsProgress(
        const GetReviewsProgressParams(limit: 10),
      );
      verify(() => mockRepository.getReviewsProgress(limit: 10)).called(1);
    });

    test('should get word progress successfully', () async {
      when(
        () => mockRepository.getWordProgressById(wordId: 1),
      ).thenAnswer((_) async => Right(wordProgress));

      final result = await getWorkProgress(
        const GetWordProgressParams(wordId: 1),
      );

      expect(result, Right(wordProgress));
      verify(() => mockRepository.getWordProgressById(wordId: 1)).called(1);
    });

    test('should get progress successfully', () async {
      when(
        () => mockRepository.getProgressById(wordId: 1),
      ).thenAnswer((_) async => Right(progress));

      final result = await getProgress(
        const GetProgressParams(wordId: 1),
      );

      expect(result, Right(progress));
      verify(() => mockRepository.getProgressById(wordId: 1)).called(1);
    });

    test('should return failure when getting reviews progress fails', () async {
      when(
        () => mockRepository.getReviewsProgress(limit: 10),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getReviewsProgress(
        const GetReviewsProgressParams(limit: 10),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getReviewsProgress(limit: 10)).called(1);
    });

    test('should return failure when getting word progress fails', () async {
      when(
        () => mockRepository.getWordProgressById(wordId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getWorkProgress(
        const GetWordProgressParams(wordId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getWordProgressById(wordId: 1)).called(1);
    });

    test('should return failure when getting progress fails', () async {
      when(
        () => mockRepository.getProgressById(wordId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await getProgress(
        const GetProgressParams(wordId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.getProgressById(wordId: 1)).called(1);
    });
  });

  group('DeleteProgress Use Case', () {
    test('should delete progress successfully', () async {
      when(
        () => mockRepository.deleteProgress(wordId: 1),
      ).thenAnswer((_) async => const Right(Success()));

      final result = await deleteProgress(
        const DeleteProgressParams(wordId: 1),
      );

      expect(result, const Right(Success()));
      verify(() => mockRepository.deleteProgress(wordId: 1)).called(1);
    });

    test('should return failure when deleting progress fails', () async {
      when(
        () => mockRepository.deleteProgress(wordId: 1),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await deleteProgress(
        const DeleteProgressParams(wordId: 1),
      );

      expect(result, const Left(ServerFailure(message: 'Error')));
      verify(() => mockRepository.deleteProgress(wordId: 1)).called(1);
    });
  });
}
