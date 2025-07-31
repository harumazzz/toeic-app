import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../i18n/strings.g.dart';
import '../../../domain/entities/word.dart';

class HeroWordHeader extends StatelessWidget {
  const HeroWordHeader({
    required this.word,
    super.key,
  });

  final Word word;
  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLightMode = colorScheme.brightness == Brightness.light;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
      ),
      child: SafeArea(
        bottom: false,
        child: Card(
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLightMode 
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLightMode 
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.school,
                        size: 14,
                        color: isLightMode 
                            ? colorScheme.primary
                            : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${context.t.common.level} ${word.level}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isLightMode 
                              ? colorScheme.primary
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isLightMode 
                        ? colorScheme.onSurface
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLightMode 
                        ? colorScheme.surfaceContainer
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLightMode 
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.translate,
                        color: isLightMode 
                            ? colorScheme.primary
                            : Colors.white,
                        size: 18,
                      ),
                      if (word.shortMean != null &&
                          word.shortMean!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            word.shortMean!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: isLightMode 
                                  ? colorScheme.onSurface
                                  : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
