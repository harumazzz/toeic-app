import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/text_analyze.dart';
import '../../domain/entities/user_writing.dart';
import '../providers/user_writing_provider.dart';

class WritingViewScreen extends HookConsumerWidget {
  const WritingViewScreen({
    required this.writing,
    super.key,
  });
  final UserWriting writing;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final analysisState = ref.watch(userWritingAnalysisControllerProvider);

    // Trigger analysis when the screen loads
    useEffect(() {
      if (writing.submissionText.isNotEmpty) {
        Future.microtask(() {
          ref
              .read(userWritingAnalysisControllerProvider.notifier)
              .analyzeWriting(
                TextAnalyzeRequest(
                  minSynonymLevel: 'A1',
                  text: writing.submissionText,
                ),
              );
        });
      }
      return null;
    }, [writing.submissionText]);

    return _WritingViewContent(
      writing: writing,
      analysisState: analysisState,
      onDelete: () async {
        if (authState is AuthAuthenticated) {
          final success = await ref
              .read(userWritingsByUserControllerProvider.notifier)
              .deleteWriting(writing.id, authState.user.id);

          if (context.mounted) {
            if (success) {
              ToastService.success(
                context: context,
                message: t.writingAnalysis.writingDeletedSuccessfully,
              );
              Navigator.of(context).pop();
            } else {
              ToastService.error(
                context: context,
                message: t.writingAnalysis.failedToDeleteWriting,
              );
            }
          }
        }
      },
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<UserWriting>('writing', writing));
  }
}

class _WritingViewContent extends StatelessWidget {
  const _WritingViewContent({
    required this.writing,
    required this.analysisState,
    this.onDelete,
  });
  final UserWriting writing;
  final UserWritingAnalysisState analysisState;
  final VoidCallback? onDelete;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.writing.writingDetails,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            onPressed: () => _showDeleteDialog(context),
            icon: Icon(
              Symbols.delete_outline,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WritingMetadataCard(writing: writing),
            const SizedBox(height: 12),
            WritingContentCard(writing: writing),
            const SizedBox(height: 12),
            // Add the vocabulary analysis section
            _AnalysisSection(
              analysisState: analysisState,
              wordCount: _getWordCount(writing.submissionText),
              content: writing.submissionText,
            ),
            if (writing.aiFeedback != null) ...[
              const SizedBox(height: 12),
              AiFeedbackCard(feedback: writing.aiFeedback!),
            ],
          ],
        ),
      ),
    );
  }

  int _getWordCount(final String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  void _showDeleteDialog(final BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
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
            onPressed: () async {
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<UserWriting>('writing', writing))
      ..add(
        DiagnosticsProperty<UserWritingAnalysisState>(
          'analysisState',
          analysisState,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onDelete', onDelete));
  }
}

class WritingMetadataCard extends StatelessWidget {
  const WritingMetadataCard({required this.writing, super.key});
  final UserWriting writing;

  @override
  Widget build(final BuildContext context) =>
      _WritingMetadataContent(writing: writing);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<UserWriting>('writing', writing));
  }
}

class _WritingMetadataContent extends StatelessWidget {
  const _WritingMetadataContent({required this.writing});
  final UserWriting writing;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.info,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.writingInformation,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (writing.aiScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      writing.aiScore!,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${writing.aiScore!.toStringAsFixed(1)}/10',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getScoreColor(writing.aiScore!),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: context.t.writing.submitted,
            value: _formatDateTime(writing.submittedAt),
            icon: Symbols.schedule,
          ),
          if (writing.evaluatedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: context.t.writing.evaluated,
              value: _formatDateTime(writing.evaluatedAt!),
              icon: Symbols.check_circle_outline,
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            label: context.t.writing.wordCount,
            value:
                '${_getWordCount(
                  writing.submissionText,
                )} ${context.t.writing.words}',
            icon: Symbols.text_fields,
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

  String _formatDateTime(final DateTime date) =>
      '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  int _getWordCount(final String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<UserWriting>('writing', writing));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
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

class WritingContentCard extends StatelessWidget {
  const WritingContentCard({required this.writing, super.key});
  final UserWriting writing;

  @override
  Widget build(final BuildContext context) =>
      _WritingContentContent(writing: writing);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<UserWriting>('writing', writing));
  }
}

class _WritingContentContent extends StatelessWidget {
  const _WritingContentContent({required this.writing});
  final UserWriting writing;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.article,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.yourWriting,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              writing.submissionText,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<UserWriting>('writing', writing));
  }
}

class AiFeedbackCard extends StatelessWidget {
  const AiFeedbackCard({required this.feedback, super.key});
  final Map<String, dynamic> feedback;

  @override
  Widget build(final BuildContext context) =>
      _AiFeedbackContent(feedback: feedback);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Map<String, dynamic>>('feedback', feedback),
    );
  }
}

class _AiFeedbackContent extends StatelessWidget {
  const _AiFeedbackContent({required this.feedback});
  final Map<String, dynamic> feedback;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.05),
            theme.primaryColor.withValues(alpha: 0.02),
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
                Symbols.auto_awesome,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.aiFeedback,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...feedback.entries.map(
            (final entry) => _buildFeedbackSection(
              context,
              entry.key,
              entry.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(
    final BuildContext context,
    final String key,
    final dynamic value,
  ) {
    final theme = Theme.of(context);

    if (value is Map<String, dynamic>) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatFeedbackKey(key),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...value.entries.map(
              (final subEntry) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: _buildFeedbackItem(
                  context,
                  subEntry.key,
                  subEntry.value,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildFeedbackItem(context, key, value),
      );
    }
  }

  Widget _buildFeedbackItem(
    final BuildContext context,
    final String key,
    final dynamic value,
  ) {
    final theme = Theme.of(context);

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatFeedbackKey(key)}:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          ...value.map(
            (final item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.terminal,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatFeedbackKey(key)}: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      );
    }
  }

  String _formatFeedbackKey(final String key) => key
      .split('_')
      .map((final word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Map<String, dynamic>>('feedback', feedback),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({
    required this.analysisState,
    required this.wordCount,
    required this.content,
  });

  final UserWritingAnalysisState analysisState;
  final int wordCount;
  final String content;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Symbols.analytics,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.writingAnalysis.writingAnalysisVocabulary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Symbols.text_fields,
                label: t.writingAnalysis.words,
                value: wordCount.toString(),
              ),
              _StatItem(
                icon: Symbols.timer,
                label: t.writingAnalysis.time,
                value: _getEstimatedTime(),
              ),
              _StatItem(
                icon: Symbols.edit,
                label: t.writingAnalysis.characters,
                value: content.length.toString(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Analysis Results
          switch (analysisState) {
            UserWritingAnalysisInitial() => const _AnalysisInitial(),
            UserWritingAnalysisLoading() => const _AnalysisLoading(),
            UserWritingAnalysisLoaded(:final data) => _AnalysisResults(
              data: data,
            ),
            UserWritingAnalysisError(:final message) => _AnalysisError(
              message: message,
            ),
          },
        ],
      ),
    );
  }

  String _getEstimatedTime() {
    final minutes = (wordCount / 40).ceil();
    return '${minutes}m';
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<UserWritingAnalysisState>(
          'analysisState',
          analysisState,
        ),
      )
      ..add(IntProperty('wordCount', wordCount))
      ..add(StringProperty('content', content));
  }
}

class _AnalysisInitial extends StatelessWidget {
  const _AnalysisInitial();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.analytics,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            t.writingAnalysis.preparingAnalysis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisLoading extends StatelessWidget {
  const _AnalysisLoading();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t.writingAnalysis.analyzingYourWriting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.message});

  final String message;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${t.writingAnalysis.analysisUnavailable}: $message',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

class _AnalysisResults extends StatelessWidget {
  const _AnalysisResults({required this.data});

  final TextAnalyze data;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    if (data.result.words.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.check_circle,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.writingAnalysis.greatWorkGood,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.lightbulb,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.writingAnalysis.vocabularyRecommendations,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...data.result.words
            .take(3)
            .map((final word) => _WordRecommendation(word: word)),
        if (data.result.words.length > 3) ...[
          const SizedBox(height: 8),
          Text(
            '+${data.result.words.length - 3} more recommendations available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextAnalyze>('data', data));
  }
}

class _WordRecommendation extends StatelessWidget {
  const _WordRecommendation({required this.word});

  final Word word;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(
                    word.level,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word.word,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getLevelColor(word.level, theme),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Level ${word.level}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Used ${word.count}x',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (word.suggestions != null && word.suggestions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try: ${word.suggestions!.take(2).map((final s) => s.word).join(
                ', ',
              )}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(final String level, final ThemeData theme) {
    switch (level.toUpperCase()) {
      case 'A1':
      case 'A2':
        return Colors.green;
      case 'B1':
      case 'B2':
        return Colors.orange;
      case 'C1':
      case 'C2':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value));
  }
}
