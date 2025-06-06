import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/grammar.dart';
import '../../domain/use_cases/get_grammar.dart';
import '../../domain/use_cases/get_grammars.dart';
import '../../domain/use_cases/search_grammar.dart';

part 'grammar_provider.freezed.dart';
part 'grammar_provider.g.dart';

@freezed
sealed class GrammarState with _$GrammarState {
  const factory GrammarState({
    @Default([]) final List<Grammar> grammars,
    @Default(false) final bool isLoading,
    @Default(false) final bool isSuccess,
    @Default(null) final String? error,
  }) = _GrammarState;
}

@freezed
sealed class GrammarDetailState with _$GrammarDetailState {
  const factory GrammarDetailState({
    @Default(null) final Grammar? grammar,
    @Default([]) final List<Grammar> relatedGrammars,
    @Default(false) final bool isLoading,
    @Default(false) final bool isSuccess,
    @Default(null) final String? error,
  }) = _GrammarDetailState;
}

@riverpod
class GrammarList extends _$GrammarList {
  @override
  GrammarState build() => const GrammarState();

  Future<void> loadGrammars({
    required final int limit,
    required final int offset,
  }) async {
    if (state.isSuccess && state.grammars.isEmpty && offset > 0) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(getGrammarsProvider)(
      GetGrammarsParams(
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: false,
                error: failure.message,
              ),
      ifRight:
          (final grammars) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: true,
                grammars:
                    offset == 0 ? grammars : [...state.grammars, ...grammars],
              ),
    );
  }

  Future<void> loadGrammarsByLevel({
    required final int level,
    required final int limit,
    required final int offset,
  }) async {
    if (state.isSuccess && state.grammars.isEmpty && offset > 0) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(getGrammarsByLevelProvider)(
      GetGrammarsByLevelParams(
        level: level,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: false,
                error: failure.message,
              ),
      ifRight:
          (final grammars) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: true,
                grammars:
                    offset == 0 ? grammars : [...state.grammars, ...grammars],
              ),
    );
  }

  Future<void> loadGrammarsByTag({
    required final int tag,
    required final int limit,
    required final int offset,
  }) async {
    if (state.isSuccess && state.grammars.isEmpty && offset > 0) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(getGrammarsByTagProvider)(
      GetGrammarsByTagParams(
        tag: tag,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: false,
                error: failure.message,
              ),
      ifRight:
          (final grammars) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: true,
                grammars:
                    offset == 0 ? grammars : [...state.grammars, ...grammars],
              ),
    );
  }

  Future<void> searchGrammars({
    required final String query,
    required final int limit,
    required final int offset,
  }) async {
    if (state.isSuccess && state.grammars.isEmpty && offset > 0) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(searchGrammarProvider)(
      SearchGrammarsParams(
        query: query,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: false,
                error: failure.message,
              ),
      ifRight:
          (final grammars) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: true,
                grammars:
                    offset == 0 ? grammars : [...state.grammars, ...grammars],
              ),
    );
  }
}

@riverpod
class GrammarDetail extends _$GrammarDetail {
  @override
  GrammarDetailState build() => const GrammarDetailState();

  Future<void> loadGrammar(final int id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(getGrammarProvider)(
      GetGrammarParams(id: id),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                isLoading: false,
                isSuccess: false,
                error: failure.message,
              ),
      ifRight: (final grammar) async {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          grammar: grammar,
        );

        if (grammar.related != null && grammar.related!.isNotEmpty) {
          await loadRelatedGrammars(grammar.related!);
        }
      },
    );
  }

  Future<void> loadRelatedGrammars(final List<int> ids) async {
    final result = await ref.read(getRelatedGrammarsProvider)(
      GetRelatedGrammarsParams(ids: ids),
    );

    result.fold(
      ifLeft:
          (final failure) =>
              state = state.copyWith(
                error: failure.message,
              ),
      ifRight:
          (final grammars) =>
              state = state.copyWith(
                relatedGrammars: grammars,
              ),
    );
  }
}
