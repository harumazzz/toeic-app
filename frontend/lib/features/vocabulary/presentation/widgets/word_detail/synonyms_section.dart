import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../i18n/strings.g.dart';
import '../../../domain/entities/word.dart';

class SynonymsSection extends StatelessWidget {
  const SynonymsSection({
    required this.word,
    super.key,
  });

  final Word word;

  @override
  Widget build(final BuildContext context) => Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SynonymHeader(),
          const SizedBox(height: 12),
          if (word.snym != null && word.snym!.isNotEmpty) ...[
            for (final synonymGroup in word.snym!)
              SynonymGroupItem(synonym: synonymGroup),
            const SizedBox(height: 12),
          ] else
            Text(
              context.t.wordDetail.noSynonyms,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

class SynonymHeader extends StatelessWidget {
  const SynonymHeader({super.key});

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Symbols.swap_horiz,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        context.t.wordDetail.synonymsAndAntonyms,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    ],
  );
}

class SynonymGroupItem extends StatelessWidget {
  const SynonymGroupItem({
    required this.synonym,
    super.key,
  });

  final Synonym synonym;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (synonym.kind != null) SynonymKindBadge(kind: synonym.kind!),
      if (synonym.content != null) ...[
        for (
          var contentIndex = 0;
          contentIndex < synonym.content!.length;
          contentIndex++
        ) ...[
          SynonymContentItem(content: synonym.content![contentIndex]),
          const SizedBox(height: 12),
        ],
      ],
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Synonym>('synonym', synonym));
  }
}

class SynonymKindBadge extends StatelessWidget {
  const SynonymKindBadge({
    required this.kind,
    super.key,
  });

  final String kind;
  @override
  Widget build(final BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          kind,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('kind', kind));
  }
}

class SynonymContentItem extends StatelessWidget {
  const SynonymContentItem({
    required this.content,
    super.key,
  });

  final Content content;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (content.synonym != null && content.synonym!.isNotEmpty)
        WordListContainer(
          words: content.synonym!,
          type: WordListType.synonym,
        ),
      if (content.synonym != null &&
          content.synonym!.isNotEmpty &&
          content.antonym != null &&
          content.antonym!.isNotEmpty)
        const SizedBox(height: 8),
      if (content.antonym != null && content.antonym!.isNotEmpty)
        WordListContainer(
          words: content.antonym!,
          type: WordListType.antonym,
        ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Content>('content', content));
  }
}

enum WordListType { synonym, antonym }

class WordListContainer extends StatelessWidget {
  const WordListContainer({
    required this.words,
    required this.type,
    super.key,
  });

  final List<String> words;
  final WordListType type;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAntonym = type == WordListType.antonym;
    final color = isAntonym ? colorScheme.error : colorScheme.tertiary;
    final icon = isAntonym ? Symbols.remove_circle : Symbols.add_circle;
    final title =
        isAntonym
            ? context.t.wordDetail.antonyms
            : context.t.wordDetail.synonyms;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final word in words)
                WordChip(
                  word: word,
                  color: color,
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('words', words))
      ..add(EnumProperty<WordListType>('type', type));
  }
}

class WordChip extends StatelessWidget {
  const WordChip({
    required this.word,
    required this.color,
    super.key,
  });

  final String word;
  final Color color;
  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
      ),
    ),
    child: Text(
      word,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('word', word))
      ..add(ColorProperty('color', color));
  }
}

class SynonymDivider extends StatelessWidget {
  const SynonymDivider({super.key});
  @override
  Widget build(final BuildContext context) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
