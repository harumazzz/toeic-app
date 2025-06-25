import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';

class WritingStatsCard extends StatelessWidget {
  const WritingStatsCard({
    required this.totalWritings,
    required this.averageScore,
    required this.wordsWritten,
    required this.completedPrompts,
    super.key,
  });
  final int totalWritings;
  final double averageScore;
  final int wordsWritten;
  final int completedPrompts;

  @override
  Widget build(final BuildContext context) => _WritingStatsCardContent(
    totalWritings: totalWritings,
    averageScore: averageScore,
    wordsWritten: wordsWritten,
    completedPrompts: completedPrompts,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('totalWritings', totalWritings))
      ..add(DoubleProperty('averageScore', averageScore))
      ..add(IntProperty('wordsWritten', wordsWritten))
      ..add(IntProperty('completedPrompts', completedPrompts));
  }
}

class _WritingStatsCardContent extends StatelessWidget {
  const _WritingStatsCardContent({
    required this.totalWritings,
    required this.averageScore,
    required this.wordsWritten,
    required this.completedPrompts,
  });

  final int totalWritings;
  final double averageScore;
  final int wordsWritten;
  final int completedPrompts;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.analytics,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.writingStatistics,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: context.t.writing.totalWritings,
                  value: totalWritings.toString(),
                  icon: Symbols.edit_note,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: context.t.writing.averageScore,
                  value:
                      averageScore > 0
                          ? '${averageScore.toStringAsFixed(1)}/10'
                          : 'N/A',
                  icon: Symbols.star_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: context.t.writing.wordsWritten,
                  value: _formatNumber(wordsWritten),
                  icon: Symbols.text_fields,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: context.t.writing.promptsDone,
                  value: completedPrompts.toString(),
                  icon: Symbols.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(final int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('totalWritings', totalWritings))
      ..add(DoubleProperty('averageScore', averageScore))
      ..add(IntProperty('wordsWritten', wordsWritten))
      ..add(IntProperty('completedPrompts', completedPrompts));
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value))
      ..add(DiagnosticsProperty<IconData>('icon', icon));
  }
}
