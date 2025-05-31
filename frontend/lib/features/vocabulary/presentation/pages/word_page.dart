import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/word.dart' as entity;
import '../providers/word_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/word_shimmer.dart';
import '../widgets/words_loading.dart' as widgets;

class WordPage extends HookConsumerWidget {
  const WordPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final scrollController = useScrollController();
    final wordState = ref.watch(wordControllerProvider);
    final offset = useState(0);
    final isSearching = useState(false);
    final isFetching = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();
    final isFirstSearchRender = useRef(true);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (wordState.words.isEmpty) {
          await ref.read(wordControllerProvider.notifier).loadWords();
        }
      });
      return null;
    }, []);
    useEffect(
      () {
        Future<void> onScroll() async {
          if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
            if (wordState is WordLoaded && !wordState.isFinished) {
              if (searchQuery.value.isEmpty) {
                await ref
                    .read(wordControllerProvider.notifier)
                    .loadWords(offset: offset.value);
                offset.value++;
              } else {
                await ref
                    .read(wordControllerProvider.notifier)
                    .searchWords(
                      query: searchQuery.value,
                      offset: offset.value,
                    );
                offset.value++;
              }
            }
          }
        }

        scrollController.addListener(onScroll);
        return () => scrollController.removeListener(onScroll);
      },
      [scrollController, wordState, searchQuery.value],
    );

    useEffect(() {
      if (isFirstSearchRender.value) {
        isFirstSearchRender.value = false;
        return null;
      }
      final timer = Timer(
        const Duration(milliseconds: 700),
        () async {
          if (isFetching.value) {
            return;
          }

          isFetching.value = true;
          if (searchQuery.value.isEmpty) {
            await ref.read(wordControllerProvider.notifier).refreshWords();
          } else {
            await ref
                .read(wordControllerProvider.notifier)
                .searchWords(
                  query: searchQuery.value,
                );
          }
          offset.value = 0;
          isFetching.value = false;
        },
      );

      return timer.cancel;
    }, [searchQuery.value]);

    Future<void> handleRefresh() async {
      offset.value = 0;
      if (searchQuery.value.isEmpty) {
        await ref.read(wordControllerProvider.notifier).refreshWords();
      } else {
        await ref
            .read(wordControllerProvider.notifier)
            .searchWords(
              query: searchQuery.value,
            );
      }
    }

    return RefreshIndicator(
      onRefresh: handleRefresh,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          _WordAppBar(
            isSearching: isSearching,
            searchController: searchController,
            searchQuery: searchQuery,
          ),
          if (wordState is WordLoading && wordState.words.isEmpty)
            const SliverFillRemaining(
              child: widgets.WordsLoading(),
            )
          else if (wordState is WordLoaded && wordState.words.isEmpty)
            const SliverFillRemaining(
              child: _EmptyStateWidget(),
            )
          else
            _WordListWidget(
              wordState: wordState,
              ref: ref,
              offset: offset,
            ),
        ],
      ),
    );
  }
}

class _WordAppBar extends HookConsumerWidget {
  const _WordAppBar({
    required this.isSearching,
    required this.searchController,
    required this.searchQuery,
    super.key,
  });

  final ValueNotifier<bool> isSearching;

  final TextEditingController searchController;

  final ValueNotifier<String> searchQuery;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => SliverAppBar(
    title:
        isSearching.value
            ? TextField(
              keyboardType: TextInputType.text,
              controller: searchController,
              decoration: InputDecoration(
                hintText: context.t.common.search,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
              ),

              onChanged: (final value) {
                searchQuery.value = value;
              },
            )
            : Text(context.t.page.vocabulary),
    actions: [
      IconButton(
        icon: Icon(isSearching.value ? Symbols.close : Symbols.search),
        onPressed: () async {
          isSearching.value = !isSearching.value;
          if (!isSearching.value) {
            searchController.clear();
            searchQuery.value = '';
          }
        },
      ),
    ],
    floating: true,
    snap: true,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ValueNotifier<bool>>('isSearching', isSearching),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'searchController',
          searchController,
        ),
      )
      ..add(
        DiagnosticsProperty<ValueNotifier<String>>('searchQuery', searchQuery),
      );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({super.key});

  @override
  Widget build(final BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Symbols.search_off,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          context.t.common.noDataFound,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
  );
}

class _WordListWidget extends StatelessWidget {
  const _WordListWidget({
    required this.wordState,
    required this.ref,
    required this.offset,
  });
  final WordState wordState;
  final WidgetRef ref;
  final ValueNotifier<int> offset;

  @override
  Widget build(final BuildContext context) => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (final BuildContext context, final int index) {
          if (index < wordState.words.length) {
            final word = wordState.words[index];
            return _WordCardItem(word: word);
          } else if (wordState is WordLoading) {
            return const WordShimmer();
          } else if (wordState is WordError) {
            return _ErrorStateWidget(
              wordState: wordState as WordError,
              ref: ref,
              offset: offset,
            );
          }
          return null;
        },
        childCount:
            wordState.words.length +
            (wordState is WordLoaded && (wordState as WordLoaded).isFinished
                ? 0
                : 1),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<WordState>('wordState', wordState))
      ..add(DiagnosticsProperty<WidgetRef>('ref', ref))
      ..add(DiagnosticsProperty<ValueNotifier<int>>('offset', offset));
  }
}

class _WordCardItem extends StatelessWidget {
  const _WordCardItem({
    required this.word,
  });
  final entity.Word word;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: WordCard(word: word),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<entity.Word>('word', word));
  }
}

class _ErrorStateWidget extends StatelessWidget {
  const _ErrorStateWidget({
    required this.wordState,
    required this.ref,
    required this.offset,
  });

  final WordError wordState;

  final WidgetRef ref;

  final ValueNotifier<int> offset;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        children: [
          Text(
            wordState.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(wordControllerProvider.notifier)
                  .loadWords(
                    offset: wordState.words.length ~/ 20,
                  );
            },
            child: Text(context.t.common.retry),
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<WordError>('wordState', wordState))
      ..add(DiagnosticsProperty<WidgetRef>('ref', ref))
      ..add(DiagnosticsProperty<ValueNotifier<int>>('offset', offset));
  }
}
