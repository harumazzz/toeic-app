import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/user_writing.dart';

class WritingHistoryCard extends StatelessWidget {
  const WritingHistoryCard({
    required this.writing,
    this.onTap,
    this.onDelete,
    super.key,
  });
  final UserWriting writing;
  final void Function()? onTap;
  final void Function()? onDelete;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.article,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t.writing.writingSubmission,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (writing.aiScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(
                          writing.aiScore!,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${writing.aiScore!.toStringAsFixed(1)}/10',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getScoreColor(writing.aiScore!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDeleteDialog(context),
                    icon: Icon(
                      Symbols.delete_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                writing.submissionText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Symbols.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.t.writing.submitted.replaceAll(
                      '{}',
                      _formatDate(writing.submittedAt),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (writing.evaluatedAt != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Symbols.check_circle_outline,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.t.writing.evaluated,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(final BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (final context) => AlertDialog(
            title: Text(context.t.writing.deleteWriting),
            content: Text(
              context.t.writing.deleteWritingConfirm,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.t.common.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(context.t.common.delete),
              ),
            ],
          ),
    );
  }

  Color _getScoreColor(final double score) {
    if (score >= 8.0) {
      return Colors.green;
    }
    if (score >= 6.0) {
      return Colors.orange;
    }
    return Colors.red;
  }

  String _formatDate(final DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<UserWriting>('writing', writing))
      ..add(ObjectFlagProperty<void Function()?>.has('onTap', onTap))
      ..add(ObjectFlagProperty<void Function()?>.has('onDelete', onDelete));
  }
}
