import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/grammar_provider.dart';
import '../widgets/grammar_list_item.dart';
import '../widgets/grammar_list_item_shimmer.dart';

class GrammarListScreen extends HookConsumerWidget {
  const GrammarListScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final scrollController = useScrollController();
    final currentPage = useState(0);
    final hasReachedEnd = useState(false);
    final searchController = useTextEditingController();
    final isSearching = useState(false);
    final debounce = useRef<Timer?>(null);
    const pageSize = 20;

    useEffect(() {
      Future<void> onScroll() async {
        if (!hasReachedEnd.value &&
            scrollController.position.pixels >=
                scrollController.position.maxScrollExtent - 200) {
          currentPage.value++;
          await Future.microtask(() async {
            if (isSearching.value) {
              await ref
                  .read(grammarListProvider.notifier)
                  .searchGrammars(
                    query: searchController.text,
                    limit: pageSize,
                    offset: currentPage.value * pageSize,
                  );
            } else {
              await ref
                  .read(grammarListProvider.notifier)
                  .loadGrammars(
                    limit: pageSize,
                    offset: currentPage.value * pageSize,
                  );
            }
            final state = ref.read(grammarListProvider);
            if (state.grammars.isEmpty) {
              hasReachedEnd.value = true;
            }
          });
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, isSearching.value, searchController.text]);

    useEffect(() {
      hasReachedEnd.value = false;
      currentPage.value = 0;
      Future.microtask(() async {
        if (isSearching.value) {
          await ref
              .read(grammarListProvider.notifier)
              .searchGrammars(
                query: searchController.text,
                limit: pageSize,
                offset: 0,
              );
        } else {
          await ref
              .read(grammarListProvider.notifier)
              .loadGrammars(
                limit: pageSize,
                offset: 0,
              );
        }
        final state = ref.read(grammarListProvider);
        if (state.grammars.isEmpty) {
          hasReachedEnd.value = true;
        }
      });
      return null;
    }, [isSearching.value, searchController.text]);

    final state = ref.watch(grammarListProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (final value) {
            debounce.value?.cancel();
            debounce.value = Timer(const Duration(milliseconds: 400), () async {
              isSearching.value = value.trim().isNotEmpty;
              hasReachedEnd.value = false;
              currentPage.value = 0;
              if (isSearching.value) {
                await ref
                    .read(grammarListProvider.notifier)
                    .searchGrammars(
                      query: value.trim(),
                      limit: pageSize,
                      offset: 0,
                    );
              } else {
                await ref
                    .read(grammarListProvider.notifier)
                    .loadGrammars(
                      limit: pageSize,
                      offset: 0,
                    );
              }
            });
          },
          decoration: InputDecoration(
            hintText: context.t.grammar.searchHint,
            border: InputBorder.none,
            suffixIcon:
                searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Symbols.clear),
                      onPressed: () async {
                        searchController.clear();
                        isSearching.value = false;
                        await ref
                            .read(grammarListProvider.notifier)
                            .loadGrammars(
                              limit: pageSize,
                              offset: 0,
                            );
                      },
                    )
                    : null,
          ),
          textInputAction: TextInputAction.search,
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
      ),
      body: Builder(
        builder: (final context) {
          if (state.isLoading && state.grammars.isEmpty) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder:
                  (final context, final index) =>
                      const GrammarListItemShimmer(),
            );
          } else if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.t.grammar.errorOccurred),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (isSearching.value) {
                        ref
                            .read(grammarListProvider.notifier)
                            .searchGrammars(
                              query: searchController.text,
                              limit: pageSize,
                              offset: 0,
                            );
                      } else {
                        ref
                            .read(grammarListProvider.notifier)
                            .loadGrammars(
                              limit: pageSize,
                              offset: 0,
                            );
                      }
                    },
                    child: Text(context.t.common.retry),
                  ),
                ],
              ),
            );
          } else if (state.grammars.isEmpty) {
            return Center(child: Text(context.t.grammar.noGrammarsFound));
          } else {
            return ListView.builder(
              controller: scrollController,
              itemCount:
                  state.grammars.length +
                  (state.isLoading && !hasReachedEnd.value ? 1 : 0),
              itemBuilder: (final context, final index) {
                if (index == state.grammars.length &&
                    state.isLoading &&
                    !hasReachedEnd.value) {
                  return const GrammarListItemShimmer();
                }
                if (index >= state.grammars.length) {
                  return null;
                }
                final grammar = state.grammars[index];
                return GrammarListItem(
                  grammar: grammar,
                  onTap: () async {
                    await GrammarDetailRoute(
                      grammarId: grammar.id,
                    ).push(context);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
