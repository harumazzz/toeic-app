import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/word.dart';
import '../providers/word_detail_provider.dart';
import '../widgets/word_detail/collapsible_action_button.dart';
import '../widgets/word_detail/conjugation_section.dart';
import '../widgets/word_detail/detailed_meanings.dart';
import '../widgets/word_detail/hero_word_header.dart';
import '../widgets/word_detail/pronunciation_card.dart';
import '../widgets/word_detail/quick_stats_row.dart';
import '../widgets/word_detail/synonyms_section.dart';
import '../widgets/word_detail/word_detail_error.dart' as word_detail_error;
import '../widgets/word_detail/word_detail_shimmer.dart';

class WordDetailScreen extends HookConsumerWidget {
  const WordDetailScreen({
    required this.wordId,
    super.key,
  });

  final int wordId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final wordProvider = ref.read(wordDetailControllerProvider.notifier);
        await wordProvider.loadWord(wordId);
      });
      return null;
    }, [wordId]);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.page.wordDetails),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: switch (ref.watch(wordDetailControllerProvider)) {
        WordDetailInitial() => const WordDetailShimmer(),
        WordDetailLoading() => const WordDetailShimmer(),
        final WordDetailLoaded state => WordDetailContent(word: state.word),
        final WordDetailError state => word_detail_error.WordDetailError(
          message: state.message,
          wordId: wordId,
        ),
      },
      floatingActionButton: switch (ref.watch(wordDetailControllerProvider)) {
        final WordDetailLoaded state => CollapsibleActionButton(
          word: state.word,
        ),
        _ => null,
      },
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('wordId', wordId));
  }
}

class WordDetailContent extends StatelessWidget {
  const WordDetailContent({
    required this.word,
    super.key,
  });

  final Word word;
  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroWordHeader(word: word),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PronunciationCard(word: word),
              const SizedBox(height: 6),
              QuickStatsRow(word: word),
              const SizedBox(height: 6),
              if (word.means != null && word.means!.isNotEmpty) ...[
                DetailedMeanings(word: word),
                const SizedBox(height: 6),
              ],
              if (word.snym != null && word.snym!.isNotEmpty) ...[
                SynonymsSection(word: word),
                const SizedBox(height: 6),
              ],
              if (word.conjugation != null) ...[
                ConjugationSection(word: word),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}
