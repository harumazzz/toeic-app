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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SynonymHeader(),
          const SizedBox(height: 16),
          for (int index = 0; index < word.snym.length; index++) ...[
            SynonymGroupItem(
              synonym: word.snym[index],
            ),
            if (index < word.snym.length - 1) const SynonymDivider(),
          ],
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Symbols.swap_horiz,
          size: 18,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      const SizedBox(width: 12),
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
          int contentIndex = 0;
          contentIndex < synonym.content!.length;
          contentIndex++
        ) ...[
          SynonymContentItem(content: synonym.content![contentIndex]),
          if (contentIndex < synonym.content!.length - 1)
            const SizedBox(height: 16),
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
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          kind,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      const SizedBox(height: 16),
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
        const SizedBox(height: 12),
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
    final isAntonym = type == WordListType.antonym;
    final color = isAntonym ? Colors.red : Colors.green;
    final icon = isAntonym ? Symbols.remove_circle : Symbols.add_circle;
    final title =
        isAntonym
            ? context.t.wordDetail.antonyms
            : context.t.wordDetail.synonyms;

    return Container(
      padding: const EdgeInsets.all(16),
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
                size: 16,
                color: color.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
  final MaterialColor color;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
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
        color: color.shade700,
        fontWeight: FontWeight.w500,
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
      const SizedBox(height: 24),
      Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
      const SizedBox(height: 24),
    ],
  );
}
