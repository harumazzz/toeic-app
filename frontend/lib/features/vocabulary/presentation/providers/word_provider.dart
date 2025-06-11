import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/word.dart';
import '../../domain/use_cases/get_all_word.dart';
import '../../domain/use_cases/search_word.dart';

part 'word_provider.freezed.dart';
part 'word_provider.g.dart';

@freezed
sealed class WordState with _$WordState {
  const factory WordState.initial({
    required final List<Word> words,
  }) = WordInitial;

  const factory WordState.loading({
    required final List<Word> words,
  }) = WordLoading;

  const factory WordState.loaded({
    required final List<Word> words,
    required final bool isFinished,
  }) = WordLoaded;

  const factory WordState.error({
    required final List<Word> words,
    required final String message,
  }) = WordError;
}

@Riverpod(keepAlive: true)
class WordController extends _$WordController {
  @override
  WordState build() => const WordState.initial(words: []);
  Future<void> loadWords({
    final int offset = 0,
    final int limit = 20,
  }) async {
    if (state is WordLoading) {
      return;
    }
    state = WordState.loading(words: state.words);
    final currentWords = state.words;
    final getAllWord = ref.read(getAllWordProvider);
    final result = await getAllWord(
      GetAllWordParams(
        offset: offset,
        limit: limit,
      ),
    );
    state = result.fold(
      ifLeft:
          (final e) => WordState.error(
            words: currentWords,
            message: e.message,
          ),
      ifRight: (final words) {
        final isFinished = words.isEmpty;
        return WordState.loaded(
          words: [...currentWords, ...words],
          isFinished: isFinished,
        );
      },
    );
  }

  Future<void> refreshWords() async {
    state = const WordState.initial(words: []);
    await loadWords();
  }

  Future<void> searchWords({
    required final String query,
    final int offset = 0,
    final int limit = 20,
  }) async {
    if (state is WordLoading) {
      return;
    }
    state = WordState.loading(words: state.words);
    final List<Word> currentWords = query.isEmpty ? [] : state.words;

    if (query.isEmpty) {
      await loadWords();
      return;
    }

    final searchWord = ref.read(searchWordProvider);
    final result = await searchWord(
      SearchWordParams(
        query: query,
        offset: offset,
        limit: limit,
      ),
    );

    state = result.fold(
      ifLeft:
          (final e) => WordState.error(
            words: currentWords,
            message: e.message,
          ),
      ifRight: (final List<Word> words) {
        final isFinished = words.isEmpty;
        return WordState.loaded(
          words:
              offset > 0
                  ? HashSet<Word>.from([...currentWords, ...words]).toList()
                  : words,
          isFinished: isFinished,
        );
      },
    );
  }

  void reset() {
    state = const WordState.initial(words: []);
  }
}
