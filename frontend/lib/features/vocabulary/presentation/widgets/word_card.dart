import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../domain/entities/word.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    required this.word,
    super.key,
  });

  final Word word;
  @override
  Widget build(final BuildContext context) => InkWell(
    onTap: () async {
      await WordDetailRoute(wordId: word.id).push(context);
    },
    borderRadius: BorderRadius.circular(12),
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(context, word.level),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${context.t.common.level} ${word.level}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () async {
                        // TODO(dev): Implement pronunciation playback
                      },
                      child: const Icon(
                        Symbols.volume_up,
                        size: 20,
                      ),
                    ),
                    Text(
                      word.pronounce,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: context.t.common.learn,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {},
                  icon: const Icon(Symbols.school),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              word.shortMean,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (word.descriptLevel.isNotEmpty)
              Text(
                word.descriptLevel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

Color _getLevelColor(
  final BuildContext context,
  final int level,
) {
  final colorScheme = Theme.of(context).colorScheme;
  switch (level) {
    case 1:
      return Colors.green;
    case 2:
      return Colors.blue;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.red;
    case 5:
      return Colors.purple;
    default:
      return colorScheme.primary;
  }
}
