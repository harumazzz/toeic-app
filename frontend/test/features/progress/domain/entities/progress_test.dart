import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/progress/domain/entities/progress.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';

void main() {
  group('Progress Entity Tests', () {
    test('should create a valid Progress instance', () {
      final progress = Progress(
        createdAt: DateTime(2024),
        easeFactor: 2,
        intervalDays: 1,
        lastReviewedAt: DateTime(2024),
        nextReviewAt: DateTime(2024, 1, 2),
        repetitions: 0,
        updatedAt: DateTime(2024),
        userId: 1,
        wordId: 1,
      );

      expect(progress.createdAt, DateTime(2024));
      expect(progress.easeFactor, 2);
      expect(progress.intervalDays, 1);
      expect(progress.lastReviewedAt, DateTime(2024));
      expect(progress.nextReviewAt, DateTime(2024, 1, 2));
      expect(progress.repetitions, 0);
      expect(progress.updatedAt, DateTime(2024));
      expect(progress.userId, 1);
      expect(progress.wordId, 1);
    });

    test('should create a valid WordProgress instance', () {
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
        createdAt: DateTime(2024),
        easeFactor: 2,
        intervalDays: 1,
        lastReviewedAt: DateTime(2024),
        nextReviewAt: DateTime(2024, 1, 2),
        repetitions: 0,
        updatedAt: DateTime(2024),
        userId: 1,
        wordId: 1,
      );

      final wordProgress = WordProgress(
        progress: progress,
        word: word,
      );

      expect(wordProgress.progress, progress);
      expect(wordProgress.word, word);
    });

    test('should create a valid WordProgressRequest instance', () {
      final request = WordProgressRequest(
        easeFactor: 2,
        intervalDays: 1,
        lastReviewedAt: DateTime(2024),
        nextReviewAt: DateTime(2024, 1, 2),
        repetitions: 0,
        wordId: 1,
      );

      expect(request.easeFactor, 2);
      expect(request.intervalDays, 1);
      expect(request.lastReviewedAt, DateTime(2024));
      expect(request.nextReviewAt, DateTime(2024, 1, 2));
      expect(request.repetitions, 0);
      expect(request.wordId, 1);
    });

    test('should create a valid CreateWordProgress instance', () {
      final createProgress = CreateWordProgress(
        easeFactor: 2,
        intervalDays: 1,
        lastReviewedAt: DateTime(2024),
        nextReviewAt: DateTime(2024, 1, 2),
        repetitions: 0,
        wordId: 1,
      );

      expect(createProgress.easeFactor, 2);
      expect(createProgress.intervalDays, 1);
      expect(createProgress.lastReviewedAt, DateTime(2024));
      expect(createProgress.nextReviewAt, DateTime(2024, 1, 2));
      expect(createProgress.repetitions, 0);
      expect(createProgress.wordId, 1);
    });
  });
}
