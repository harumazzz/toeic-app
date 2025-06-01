import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    state = const WordDetailState.loading();
    final getWordUseCase = ref.read(getWordProvider);

    final result = await getWordUseCase(GetWordParams(id: wordId));

    state = result.fold(
      ifLeft:
          (final e) => WordDetailState.error(
            message: e.message,
          ),
      ifRight:
          (final word) => WordDetailState.loaded(
            word: word,
          ),
    );
  }
}
