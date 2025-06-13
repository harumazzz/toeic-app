import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';

class ExamCard extends StatelessWidget {
  const ExamCard({
    required this.exam,
    this.onTap,
    super.key,
  });

  final Exam exam;
  final void Function()? onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        onTap: onTap ?? () => _showExamDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.8),
                colorScheme.secondaryContainer.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ExamIcon(
                      icon: Symbols.quiz,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExamTitle(
                            title: exam.title,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 6),
                          _ExamMetadata(
                            duration: exam.timeLimitMinutes,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActionButton(
                      onPressed: onTap ?? () => _showExamDialog(context),
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ExamStats(
                  difficulty: _getDifficultyLevel(exam.timeLimitMinutes),
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyLevel(final int duration) {
    if (duration <= 30) {
      return 'Easy';
    }
    if (duration <= 60) {
      return 'Medium';
    }
    return 'Hard';
  }

  Future<void> _showExamDialog(final BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder:
          (final context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Symbols.quiz,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exam.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.practice.takeTheTest,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.schedule,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${exam.timeLimitMinutes} ${context.t.common.minutes}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t.common.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO(dev): Navigate to exam details
                },
                child: Text(context.t.common.yes),
              ),
            ],
          ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Exam>('exam', exam))
      ..add(ObjectFlagProperty<void Function()?>.has('onTap', onTap));
  }
}

class _ExamIcon extends StatelessWidget {
  const _ExamIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: backgroundColor,
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
      icon,
      color: color,
      size: 24,
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}

class _ExamTitle extends StatelessWidget {
  const _ExamTitle({
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(final BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(ColorProperty('color', color));
  }
}

class _ExamMetadata extends StatelessWidget {
  const _ExamMetadata({
    required this.duration,
    required this.color,
  });

  final int duration;
  final Color color;

  @override
  Widget build(final BuildContext context) => Row(
    children: [
      Icon(
        Symbols.schedule,
        size: 18,
        color: color,
      ),
      const SizedBox(width: 6),
      Text(
        '$duration ${context.t.common.minutes}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('duration', duration))
      ..add(ColorProperty('color', color));
  }
}

class _ExamStats extends StatelessWidget {
  const _ExamStats({
    required this.difficulty,
    required this.color,
  });

  final String difficulty;
  final Color color;
  @override
  Widget build(final BuildContext context) => Row(
    children: [
      _StatChip(
        icon: Symbols.quiz,
        label: 'Practice',
        color: color,
      ),
      const SizedBox(width: 8),
      _StatChip(
        icon: Symbols.trending_up,
        label: difficulty,
        color: color,
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('difficulty', difficulty))
      ..add(ColorProperty('color', color));
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withValues(alpha: 0.2),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(ColorProperty('color', color));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.color,
  });

  final void Function() onPressed;
  final Color color;
  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
      ),
    ),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(
        Symbols.arrow_forward,
        color: color,
        size: 18,
      ),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<void Function()>.has('onPressed', onPressed),
      )
      ..add(ColorProperty('color', color));
  }
}
