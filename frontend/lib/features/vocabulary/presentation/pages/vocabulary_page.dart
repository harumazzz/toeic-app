import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../i18n/strings.g.dart';
import '../providers/word_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/word_shimmer.dart';
import '../widgets/words_loading.dart' as widgets;

class VocabularyPage extends HookConsumerWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final scrollController = useScrollController();
    final wordState = ref.watch(wordControllerProvider);
    final offset = useState(0);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (wordState.words.isEmpty) {
          await ref.read(wordControllerProvider.notifier).loadWords();
        }
      });
      return null;
    }, []);
    useEffect(() {
      Future<void> onScroll() async {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          if (wordState is WordLoaded && !wordState.isFinished) {
            await ref
                .read(wordControllerProvider.notifier)
                .loadWords(offset: offset.value);
            offset.value++;
          }
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, wordState]);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh:
            () async =>
                ref.read(wordControllerProvider.notifier).refreshWords(),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              title: Text(context.t.page.vocabulary),
              floating: true,
              snap: true,
            ),
            if (wordState.words.isEmpty && wordState is WordLoading)
              const SliverFillRemaining(
                child: widgets.WordsLoading(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (final BuildContext context, final int index) {
                      if (index < wordState.words.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: WordCard(word: wordState.words[index]),
                        );
                      } else if (wordState is WordLoading) {
                        return const WordShimmer();
                      } else if (wordState is WordError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  wordState.message,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
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
                                          offset: wordState.words.length,
                                        );
                                  },
                                  child: Text(context.t.common.retry),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount:
                        wordState.words.length +
                        (wordState is WordLoaded && wordState.isFinished
                            ? 0
                            : 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
