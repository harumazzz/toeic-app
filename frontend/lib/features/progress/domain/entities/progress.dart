import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vocabulary/domain/entities/word.dart';

part 'progress.freezed.dart';

@freezed
sealed class CreateWordProgress with _$CreateWordProgress {
    const factory CreateWordProgress({
      required final int easeFactor,
      required final int intervalDays,
      required final String lastReviewedAt,
      required final String nextReviewAt,
      required final int repetitions,
      required final int wordId,
    }) = _CreateWordProgress;
}

@freezed
sealed class Progress with _$Progress {
    const factory Progress({
      required final DateTime createdAt,
      required final int easeFactor,
      required final int intervalDays,
      required final String lastReviewedAt,
      required final String nextReviewAt,
      required final int repetitions,
      required final DateTime updatedAt,
      required final int userId,
      required final int wordId,
    }) = _Progress;
}

@freezed 
sealed class WordProgress with _$WordProgress {
  const factory WordProgress({
    required final Progress progress,
    required final Word word,
  }) = _Word;
}

@freezed
sealed class WordProgressRequest with _$WordProgressRequest {
    const factory WordProgressRequest({
      required final int easeFactor,
      required final int intervalDays,
      required final String lastReviewedAt,
      required final String nextReviewAt,
      required final int repetitions,
      required final int wordId,
    }) = _WordProgressRequest;
}
