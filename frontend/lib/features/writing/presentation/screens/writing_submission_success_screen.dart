import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../domain/entities/text_analyze.dart';
import '../providers/user_writing_provider.dart';

class WritingSubmissionSuccessScreen extends HookConsumerWidget {
  const WritingSubmissionSuccessScreen({
    required this.wordCount,
    required this.content,
    super.key,
    this.prompt,
  });

  final int wordCount;
  final String content;
  final String? prompt;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(userWritingAnalysisControllerProvider);

    // Trigger analysis when the screen loads
    useEffect(() {
      if (content.isNotEmpty) {
        Future.microtask(() {
          ref
              .read(userWritingAnalysisControllerProvider.notifier)
              .analyzeWriting(
                TextAnalyzeRequest(
                  minSynonymLevel: 'A1',
                  text: content,
                ),
              );
        });
      }
      return null;
    }, [content]);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48, // 24 padding * 2
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      context.t.writing.submissionSuccess.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t.writing.submissionSuccess.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Analysis Section
                    _AnalysisSection(
                      analysisState: analysisState,
                      wordCount: wordCount,
                      content: content,
                    ),

                    const SizedBox(height: 32),
                    if (content.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(
                                alpha: 0.5,
                              ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Symbols.preview,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.t.writing.submissionSuccess.preview,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              content.length > 150
                                  ? '${content.substring(0, 150)}...'
                                  : content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Spacer(),

                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              const WritingRoute().pushReplacement(context);
                            },
                            icon: const Icon(Symbols.draft),
                            label: Text(
                              context.t.writing.submissionSuccess.viewDrafts,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              const HomeRoute().go(context);
                            },
                            icon: const Icon(Symbols.home),
                            label: Text(
                              context.t.writing.submissionSuccess.backToHome,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('wordCount', wordCount))
      ..add(StringProperty('content', content))
      ..add(StringProperty('prompt', prompt));
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
                  t.writingAnalysis.writingAnalysisRecommendations,
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
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
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
