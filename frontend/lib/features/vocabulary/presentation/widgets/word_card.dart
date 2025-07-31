import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/tts_service.dart';
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
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          await WordDetailRoute(wordId: word.id).push(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHigh,
                colorScheme.surfaceContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _WordIcon(
                      level: word.level,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WordTitle(
                            word: word.word,
                            colorScheme: colorScheme,
                          ),
                          if (word.pronounce != null &&
                              word.pronounce!.isNotEmpty)
                            const SizedBox(height: 4),
                          if (word.pronounce != null &&
                              word.pronounce!.isNotEmpty)
                            _WordPronunciation(
                              pronunciation: word.pronounce!,
                              colorScheme: colorScheme,
                            ),
                        ],
                      ),
                    ),
                    _LevelBadge(
                      level: word.level,
                      descriptLevel: word.descriptLevel,
                    ),
                  ],
                ),
                if (word.shortMean != null && word.shortMean!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _WordMeaning(
                    meaning: word.shortMean!,
                    colorScheme: colorScheme,
                  ),
                ],
                const SizedBox(height: 10),
                _WordActions(
                  word: word,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

class _WordIcon extends StatelessWidget {
  const _WordIcon({
    required this.level,
    required this.colorScheme,
  });

  final int level;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    final iconData = _getIconForLevel(level);
    final color = _getLevelColor(context, level);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  IconData _getIconForLevel(final int level) {
    switch (level) {
      case 1:
        return Symbols.star;
      case 2:
        return Symbols.auto_awesome;
      case 3:
        return Symbols.diamond;
      case 4:
        return Symbols.emoji_events;
      case 5:
        return Symbols.workspace_premium;
      default:
        return Symbols.school;
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('level', level))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

class _WordTitle extends StatelessWidget {
  const _WordTitle({
    required this.word,
    required this.colorScheme,
  });

  final String word;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) => Text(
    word,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
      height: 1.2,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('word', word))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

class _WordPronunciation extends StatelessWidget {
  const _WordPronunciation({
    required this.pronunciation,
    required this.colorScheme,
  });

  final String pronunciation;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      Icon(
        Symbols.record_voice_over,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          pronunciation,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('pronunciation', pronunciation))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
    this.descriptLevel,
  });

  final int level;
  final String? descriptLevel;

  @override
  Widget build(final BuildContext context) {
    final color = _getLevelColor(context, level);
    var displayText = 'Level $level';
    if (descriptLevel != null && descriptLevel!.isNotEmpty) {
      displayText = descriptLevel!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('level', level))
      ..add(StringProperty('descriptLevel', descriptLevel));
  }
}

class _WordMeaning extends StatelessWidget {
  const _WordMeaning({
    required this.meaning,
    required this.colorScheme,
  });

  final String meaning;
  final ColorScheme colorScheme;
  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.outline.withValues(alpha: 0.1),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Symbols.translate,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            meaning,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('meaning', meaning))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

class _WordActions extends StatelessWidget {
  const _WordActions({
    required this.word,
    required this.colorScheme,
  });

  final Word word;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      _ActionChip(
        icon: Symbols.volume_up,
        label: context.t.common.audio,
        onTap: () async {
          await TTSService.speak(text: word.word);
        },
        colorScheme: colorScheme,
      ),
      const Spacer(),
      DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: IconButton(
          onPressed: () async {
            await WordDetailRoute(wordId: word.id).push(context);
          },
          icon: Icon(
            Symbols.arrow_forward,
            color: colorScheme.primary,
            size: 18,
          ),
          tooltip: context.t.common.viewDetails,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Word>('word', word))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final void Function() onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<void Function()>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme),
      );
  }
}

Color _getLevelColor(
  final BuildContext context,
  final int level,
) {
  final colorScheme = Theme.of(context).colorScheme;
  
  switch (level) {
    case 1:
      return colorScheme.tertiary; // Green equivalent
    case 2:
      return colorScheme.primary; // Blue equivalent
    case 3:
      return colorScheme.secondary; // Orange equivalent
    case 4:
      return colorScheme.error; // Red equivalent
    case 5:
      return colorScheme.tertiaryContainer; // Purple equivalent
    default:
      return colorScheme.primary;
  }
}
