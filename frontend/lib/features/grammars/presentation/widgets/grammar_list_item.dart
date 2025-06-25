import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/grammar.dart';

class GrammarListItem extends StatelessWidget {
  const GrammarListItem({
    super.key,
    required this.grammar,
    required this.onTap,
  });

  final Grammar grammar;
  final void Function() onTap;

  @override
  Widget build(final BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LevelText(level: grammar.level),
            const SizedBox(height: 4),
            _TitleText(title: grammar.title),
            if (grammar.tag != null && grammar.tag!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TagWrap(tags: grammar.tag!),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Grammar>('grammar', grammar))
      ..add(ObjectFlagProperty<void Function()>.has('onTap', onTap));
  }
}

class _LevelText extends StatelessWidget {
  const _LevelText({required this.level});
  final int level;
  @override
  Widget build(final BuildContext context) => Text(
    '${context.t.grammar.level}: $level',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w500,
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('level', level));
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title});
  final String title;
  @override
  Widget build(final BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});
  final List<String> tags;
  @override
  Widget build(final BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 2,
    children: [
      ...tags.map(
        (final tag) => Chip(
          label: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('tags', tags));
  }
}
