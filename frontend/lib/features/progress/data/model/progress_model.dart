import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vocabulary/data/models/word_model.dart';
import '../../domain/entities/progress.dart';

part 'progress_model.g.dart';
part 'progress_model.freezed.dart';

@freezed
sealed class WordProgressRequestModel with _$WordProgressRequestModel {
    const factory WordProgressRequestModel({
        @JsonKey(name: 'ease_factor')
        required final int easeFactor,
        @JsonKey(name: 'interval_days')
        required final int intervalDays,
        @JsonKey(name: 'last_reviewed_at')
        required final String lastReviewedAt,
        @JsonKey(name: 'next_review_at')
        required final String nextReviewAt,
        @JsonKey(name: 'repetitions')
        required final int repetitions,
        @JsonKey(name: 'word_id')
        required final int wordId,
    }) = _WordProgressRequestModel;

    factory WordProgressRequestModel.fromJson(
      final Map<String, dynamic> json,
    ) => _$WordProgressRequestModelFromJson(json);

    @override
    Map<String, dynamic> toJson();
}

@freezed
sealed class ProgressModel with _$ProgressModel {
    const factory ProgressModel({
      @JsonKey(name: 'created_at')
      required final DateTime createdAt,
      @JsonKey(name: 'ease_factor')
      required final int easeFactor,
      @JsonKey(name: 'interval_days')
      required final int intervalDays,
      @JsonKey(name: 'last_reviewed_at')
      required final String lastReviewedAt,
      @JsonKey(name: 'next_review_at')
      required final String nextReviewAt,
      @JsonKey(name: 'repetitions')
      required final int repetitions,
      @JsonKey(name: 'updated_at')
      required final DateTime updatedAt,
      @JsonKey(name: 'user_id')
      required final int userId,
      @JsonKey(name: 'word_id')
      required final int wordId,
    }) = _ProgressModel;

    factory ProgressModel.fromJson(
      final Map<String, dynamic> json,
    ) => _$ProgressModelFromJson(json);

    @override
    Map<String, dynamic> toJson();
}

@freezed
sealed class WordProgressModel with _$WordProgressModel {
    const factory WordProgressModel({
      required final ProgressModel progress,
      required final WordModel word,
    }) = _WordProgressModel;

    factory WordProgressModel.fromJson(
      final Map<String, dynamic> json,
    ) => _$WordProgressModelFromJson(json);

    @override
    Map<String, dynamic> toJson();
}

extension WordProgressRequestExtension on WordProgressRequest {

  WordProgressRequestModel toModel() => WordProgressRequestModel(
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    lastReviewedAt: lastReviewedAt,
    nextReviewAt: nextReviewAt,
    repetitions: repetitions,
    wordId: wordId,
  );

}

extension ProgressModelExtension on ProgressModel {

  Progress toEntity() => Progress(
    createdAt: createdAt,
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    lastReviewedAt: lastReviewedAt,
    nextReviewAt: nextReviewAt,
    repetitions: repetitions,
    updatedAt: updatedAt,
    userId: userId,
    wordId: wordId,
  );

}

extension WordProgressModelExtension on WordProgressModel {

  WordProgress toEntity() => WordProgress(
    progress: progress.toEntity(),
    word: word.toEntity(),
  );

}
