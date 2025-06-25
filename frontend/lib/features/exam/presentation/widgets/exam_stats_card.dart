import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ExamStatsCard extends StatelessWidget {
  const ExamStatsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.contentCount,
    required this.questionCount,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int contentCount;
  final int questionCount;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$contentCount contents • $questionCount questions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Symbols.arrow_forward,
          size: 16,
          color: color.withValues(alpha: 0.7),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(IntProperty('contentCount', contentCount))
      ..add(IntProperty('questionCount', questionCount));
  }
}
