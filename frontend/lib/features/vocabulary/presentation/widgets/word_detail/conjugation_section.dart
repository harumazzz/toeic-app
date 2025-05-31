import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../i18n/strings.g.dart';
import '../../../domain/entities/word.dart';

class ConjugationSection extends StatelessWidget {
  const ConjugationSection({
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Symbols.timeline,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.t.tooltip.conjugation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (word.conjugation != null) ...[
            ConjugationRow(
              label: context.t.wordDetail.simplePresent,
              wordState: word.conjugation!.simplePresent,
            ),
            ConjugationRow(
              label: context.t.wordDetail.simplePast,
              wordState: word.conjugation!.simplePast,
            ),
            ConjugationRow(
              label: context.t.wordDetail.presentContinuous,
              wordState: word.conjugation!.presentContinuous,
            ),
            ConjugationRow(
              label: context.t.wordDetail.presentParticiple,
              wordState: word.conjugation!.presentParticiple,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.info,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t.wordDetail.noConjugationInfo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

class ConjugationRow extends StatelessWidget {
  const ConjugationRow({
    required this.label,
    required this.wordState,
    super.key,
  });

  final String label;
  final WordState? wordState;

  @override
  Widget build(final BuildContext context) {
    if (wordState == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wordState!.w != null) ...[
                  Text(
                    wordState!.w!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (wordState!.p != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '/${wordState!.p!}/',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<WordState?>('wordState', wordState));
  }
}
