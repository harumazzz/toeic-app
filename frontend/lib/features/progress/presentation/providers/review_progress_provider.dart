import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/progress.dart';
import '../../domain/use_cases/get_progress.dart';

part 'review_progress_provider.freezed.dart';
part 'review_progress_provider.g.dart';

@freezed
sealed class ReviewProgressState with _$ReviewProgressState {
  const factory ReviewProgressState.initial() = ReviewProgressInitial;

  const factory ReviewProgressState.loading() = ReviewProgressLoading;

  const factory ReviewProgressState.loaded(
    final List<WordProgress> progress,
  ) = ReviewProgressLoaded;

  const factory ReviewProgressState.error(
    final String message,
  ) = ReviewProgressError;
}

@riverpod
class ReviewProgressNotifier extends _$ReviewProgressNotifier {
  @override
  ReviewProgressState build() => const ReviewProgressState.initial();

  Future<void> loadReviewProgress({
    required final int limit,
    required final int offset,
  }) async {
    state = const ReviewProgressState.loading();

    final result = await ref
        .read(getWordProgressForLearnProvider)
        .call(
          GetWordProgressForLearnParams(
            limit: limit,
            offset: offset,
          ),
        );

    state = result.fold(
      ifLeft: (final failure) => ReviewProgressState.error(
        failure.message,
      ),
      ifRight: ReviewProgressState.loaded,
    );
  }
}
