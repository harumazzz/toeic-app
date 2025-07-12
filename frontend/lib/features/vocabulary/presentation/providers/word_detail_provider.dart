import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../progress/domain/entities/progress.dart';
import '../../../progress/domain/use_cases/add_progress.dart';
import '../../../progress/domain/use_cases/delete_progress.dart';
import '../../../progress/domain/use_cases/get_progress.dart';
import '../../domain/entities/word.dart';
import '../../domain/use_cases/get_word.dart';

part 'word_detail_provider.freezed.dart';
part 'word_detail_provider.g.dart';

@freezed
sealed class WordDetailState with _$WordDetailState {
  const factory WordDetailState.initial() = WordDetailInitial;

  const factory WordDetailState.loading() = WordDetailLoading;

  const factory WordDetailState.loaded({
    required final Word word,
  }) = WordDetailLoaded;

  const factory WordDetailState.error({
    required final String message,
  }) = WordDetailError;
}

@Riverpod(keepAlive: true)
class WordDetailController extends _$WordDetailController {
  @override
  WordDetailState build() => const WordDetailState.initial();

  Future<void> loadWord(final int wordId) async {
    if (state is WordDetailLoading) {
      return;
    }
    if (state is WordDetailLoaded) {
      final currentWord = (state as WordDetailLoaded).word;
      if (currentWord.id == wordId) {
        return;
      }
    }
    state = const WordDetailState.loading();
    final getWordUseCase = ref.read(getWordProvider);
    final result = await getWordUseCase(
      GetWordParams(id: wordId),
    );
    state = result.fold(
      ifLeft: (final e) => WordDetailState.error(
        message: e.message,
      ),
      ifRight: (final word) => WordDetailState.loaded(
        word: word,
      ),
    );
  }
}

@freezed
sealed class BookMarkWordState with _$BookMarkWordState {
  const factory BookMarkWordState.initial() = BookMarkWordInitial;

  const factory BookMarkWordState.bookmarked() = BookMarkWordBookmarked;

  const factory BookMarkWordState.none() = BookMarkWordNone;

  const factory BookMarkWordState.error({
    required final String message,
  }) = BookMarkWordError;
}

@Riverpod(keepAlive: true)
class BookmarkWord extends _$BookmarkWord {
  @override
  BookMarkWordState build() => const BookMarkWordState.initial();

  Future<void> loadBookmark(
    final Word word,
  ) async {
    final getProgress = ref.read(getProgressProvider);
    final result = await getProgress.call(
      GetProgressParams(wordId: word.id),
    );
    state = result.fold(
      ifLeft: (final e) => BookMarkWordState.error(
        message: e.message,
      ),
      ifRight: (final progress) {
        if (progress != null) {
          return const BookMarkWordState.bookmarked();
        }
        return const BookMarkWordState.none();
      },
    );
  }

  Future<void> addBookmark(
    final Word word,
  ) async {
    if (state is! BookMarkWordBookmarked) {
      final createProgress = ref.read(addProgressProvider);
      await createProgress.call(
        AddProgressParams(
          request: WordProgressRequest(
            wordId: word.id,
            easeFactor: 0,
            intervalDays: 1,
            lastReviewedAt: DateTime.now(),
            nextReviewAt: DateTime.now().add(const Duration(days: 1)),
            repetitions: 1,
          ),
        ),
      );
      state = const BookMarkWordState.bookmarked();
    }
  }

  Future<void> removeBookmark(
    final Word word,
  ) async {
    if (state is BookMarkWordBookmarked) {
      final createProgress = ref.read(deleteProgressProvider);
      await createProgress.call(
        DeleteProgressParams(
          wordId: word.id,
        ),
      );
      state = const BookMarkWordState.none();
    }
  }
}
