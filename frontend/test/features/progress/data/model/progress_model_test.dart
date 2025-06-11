import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/progress/data/model/progress_model.dart';
import 'package:learn/features/vocabulary/data/models/word_model.dart';

void main() {
  group('Progress Model Tests', () {
    test('should create a valid ProgressModel instance', () {
      final model = ProgressModel(
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

      expect(model.createdAt, DateTime(2024));
      expect(model.easeFactor, 2);
      expect(model.intervalDays, 1);
      expect(model.lastReviewedAt, DateTime(2024));
      expect(model.nextReviewAt, DateTime(2024, 1, 2));
      expect(model.repetitions, 0);
      expect(model.updatedAt, DateTime(2024));
      expect(model.userId, 1);
      expect(model.wordId, 1);
    });

    test('should create a valid WordProgressModel instance', () {
      const wordModel = WordModel(
        id: 1,
        word: 'test',
        descriptLevel: 'A1',
        freq: 100,
        level: 1,
        pronounce: '/test/',
        shortMean: 'test meaning',
      );

      final progressModel = ProgressModel(
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

      final wordProgressModel = WordProgressModel(
        progress: progressModel,
        word: wordModel,
      );

      expect(wordProgressModel.progress, progressModel);
      expect(wordProgressModel.word, wordModel);
    });

    test('should create a valid WordProgressRequestModel instance', () {
      final requestModel = WordProgressRequestModel(
        easeFactor: 2,
        intervalDays: 1,
        lastReviewedAt: DateTime(2024),
        nextReviewAt: DateTime(2024, 1, 2),
        repetitions: 0,
        wordId: 1,
      );

      expect(requestModel.easeFactor, 2);
      expect(requestModel.intervalDays, 1);
      expect(requestModel.lastReviewedAt, DateTime(2024));
      expect(requestModel.nextReviewAt, DateTime(2024, 1, 2));
      expect(requestModel.repetitions, 0);
      expect(requestModel.wordId, 1);
    });

    test('should convert ProgressModel to entity', () {
      final model = ProgressModel(
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

      final entity = model.toEntity();

      expect(entity.createdAt, model.createdAt);
      expect(entity.easeFactor, model.easeFactor);
      expect(entity.intervalDays, model.intervalDays);
      expect(entity.lastReviewedAt, model.lastReviewedAt);
      expect(entity.nextReviewAt, model.nextReviewAt);
      expect(entity.repetitions, model.repetitions);
      expect(entity.updatedAt, model.updatedAt);
      expect(entity.userId, model.userId);
      expect(entity.wordId, model.wordId);
    });

    test('should convert WordProgressModel to entity', () {
      const wordModel = WordModel(
        id: 1,
        word: 'test',
        descriptLevel: 'A1',
        freq: 100,
        level: 1,
        pronounce: '/test/',
        shortMean: 'test meaning',
      );

      final progressModel = ProgressModel(
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

      final wordProgressModel = WordProgressModel(
        progress: progressModel,
        word: wordModel,
      );

      final entity = wordProgressModel.toEntity();

      expect(entity.progress.createdAt, progressModel.createdAt);
      expect(entity.progress.easeFactor, progressModel.easeFactor);
      expect(entity.progress.intervalDays, progressModel.intervalDays);
      expect(entity.progress.lastReviewedAt, progressModel.lastReviewedAt);
      expect(entity.progress.nextReviewAt, progressModel.nextReviewAt);
      expect(entity.progress.repetitions, progressModel.repetitions);
      expect(entity.progress.updatedAt, progressModel.updatedAt);
      expect(entity.progress.userId, progressModel.userId);
      expect(entity.progress.wordId, progressModel.wordId);
      expect(entity.word.id, wordModel.id);
      expect(entity.word.word, wordModel.word);
      expect(entity.word.descriptLevel, wordModel.descriptLevel);
      expect(entity.word.freq, wordModel.freq);
      expect(entity.word.level, wordModel.level);
      expect(entity.word.pronounce, wordModel.pronounce);
      expect(entity.word.shortMean, wordModel.shortMean);
    });
  });
}
