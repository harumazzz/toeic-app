import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vocabulary/domain/entities/word.dart';

part 'progress.freezed.dart';

@freezed
abstract class CreateWordProgress with _$CreateWordProgress {
  const factory CreateWordProgress({
    required final int easeFactor,
    required final int intervalDays,
    required final DateTime lastReviewedAt,
    required final DateTime nextReviewAt,
    required final int repetitions,
    required final int wordId,
  }) = _CreateWordProgress;
}

@freezed
abstract class Progress with _$Progress {
  const factory Progress({
    required final DateTime createdAt,
    required final int easeFactor,
    required final int intervalDays,
    required final DateTime lastReviewedAt,
    required final DateTime nextReviewAt,
    required final int repetitions,
    required final DateTime updatedAt,
    required final int userId,
    required final int wordId,
  }) = _Progress;
}

@freezed
abstract class WordProgress with _$WordProgress {
  const factory WordProgress({
    required final Progress progress,
    required final Word word,
  }) = _Word;
}

@freezed
abstract class WordProgressRequest with _$WordProgressRequest {
  const factory WordProgressRequest({
    required final int easeFactor,
    required final int intervalDays,
    required final DateTime lastReviewedAt,
    required final DateTime nextReviewAt,
    required final int repetitions,
    required final int wordId,
  }) = _WordProgressRequest;
}
