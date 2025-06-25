import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/writing_prompt.dart';

class WritingPromptCard extends StatelessWidget {
  const WritingPromptCard({
    required this.prompt,
    this.onTap,
    super.key,
  });
  final WritingPrompt prompt;
  final void Function()? onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.edit_note,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  if (prompt.topic != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        prompt.topic!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (prompt.difficultyLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          prompt.difficultyLevel!,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        prompt.difficultyLevel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getDifficultyColor(prompt.difficultyLevel!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prompt.promptText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t.writing.created.replaceAll(
                  '{}',
                  _formatDate(prompt.createdAt),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(final String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return Colors.green;
      case 'intermediate':
      case 'medium':
        return Colors.orange;
      case 'advanced':
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(final DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<WritingPrompt>('prompt', prompt))
      ..add(ObjectFlagProperty<void Function()?>.has('onTap', onTap));
  }
}
