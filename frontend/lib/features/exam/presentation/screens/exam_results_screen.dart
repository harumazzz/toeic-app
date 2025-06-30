import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/result.dart';

class ExamResultsScreen extends HookConsumerWidget {
  const ExamResultsScreen({
    required this.submittedAnswer,
    required this.exam,
    super.key,
  });

  final SubmittedAnswer submittedAnswer;
  final Exam exam;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedAnswerIndex = useState(0);
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.exam.results.title),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Results Summary Card
          Container(
            width: double.infinity,
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
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getScoreColor(
                          submittedAnswer.score.calculatedScore,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _getScoreIcon(submittedAnswer.score.calculatedScore),
                        color: _getScoreColor(
                          submittedAnswer.score.calculatedScore,
                        ),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.exam.results.examCompleted,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.exam.results.yourScore,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(
                          submittedAnswer.score.calculatedScore,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${submittedAnswer.score.calculatedScore}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreStatCard(
                        icon: Symbols.check_circle,
                        label: t.exam.results.correct,
                        value: submittedAnswer.score.correctAnswers.toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreStatCard(
                        icon: Symbols.cancel,
                        label: t.exam.results.incorrect,
                        value:
                            (submittedAnswer.score.totalQuestions -
                                    submittedAnswer.score.correctAnswers)
                                .toString(),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreStatCard(
                        icon: Symbols.quiz,
                        label: t.exam.results.total,
                        value: submittedAnswer.score.totalQuestions.toString(),
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Answer Review Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.fact_check,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.exam.results.reviewAnswers,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Answer Navigation
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: submittedAnswer.answers.length,
                      itemBuilder: (final context, final index) {
                        final answer = submittedAnswer.answers[index];
                        final isSelected = selectedAnswerIndex.value == index;

                        return GestureDetector(
                          onTap: () => selectedAnswerIndex.value = index,
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : answer.isCorrect
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : answer.isCorrect
                                    ? Colors.green
                                    : Colors.red,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : answer.isCorrect
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Selected Answer Details
                  Expanded(
                    child: submittedAnswer.answers.isNotEmpty
                        ? _AnswerDetailCard(
                            answer: submittedAnswer
                                .answers[selectedAnswerIndex.value],
                            exam: exam,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => const HomeRoute().go(context),
              icon: const Icon(Symbols.home),
              label: Text(t.exam.results.backToHome),
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
    );
  }

  Color _getScoreColor(final int score) {
    if (score >= 80) {
      return Colors.green;
    }
    if (score >= 60) {
      return Colors.orange;
    }
    return Colors.red;
  }

  IconData _getScoreIcon(final int score) {
    if (score >= 80) {
      return Symbols.celebration;
    }
    if (score >= 60) {
      return Symbols.sentiment_satisfied;
    }
    return Symbols.sentiment_dissatisfied;
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<SubmittedAnswer>(
          'submittedAnswer',
          submittedAnswer,
        ),
      )
      ..add(DiagnosticsProperty<Exam>('exam', exam));
  }
}

class _ScoreStatCard extends StatelessWidget {
  const _ScoreStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value))
      ..add(ColorProperty('color', color));
  }
}

class _AnswerDetailCard extends StatelessWidget {
  const _AnswerDetailCard({
    required this.answer,
    required this.exam,
  });

  final SubmitAnswerResult answer;
  final Exam exam;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;

    // Find the question from the exam
    Question? question;
    for (final part in exam.parts) {
      for (final content in part.contents) {
        for (final q in content.questions) {
          if (q.questionId == answer.questionId) {
            question = q;
            break;
          }
        }
        if (question != null) {
          break;
        }
      }
      if (question != null) {
        break;
      }
    }

    if (question == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          t.exam.results.questionNotFound,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    final safeQuestion = question;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: answer.isCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: answer.isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      answer.isCorrect ? Symbols.check : Symbols.close,
                      size: 16,
                      color: answer.isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      answer.isCorrect
                          ? t.exam.results.correct
                          : t.exam.results.incorrect,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: answer.isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                t.exam.results.questionNumber(number: answer.questionId),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question Text
          Text(
            safeQuestion.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          if (safeQuestion.imageUrl?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                safeQuestion.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (final context, final error, final stackTrace) =>
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Symbols.broken_image),
                      ),
                    ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Answer Options
          Text(
            t.exam.results.answerOptions,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          ...safeQuestion.possibleAnswers.asMap().entries.map((final entry) {
            final index = entry.key;
            final answerOption = entry.value;
            final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = answer.selectedAnswer == optionLabel;
            final isCorrect = safeQuestion.trueAnswer == optionLabel;

            Color? backgroundColor;
            Color? borderColor;
            Color? textColor;

            if (isSelected && isCorrect) {
              // Selected and correct
              backgroundColor = Colors.green.withValues(alpha: 0.1);
              borderColor = Colors.green;
              textColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              // Selected but incorrect
              backgroundColor = Colors.red.withValues(alpha: 0.1);
              borderColor = Colors.red;
              textColor = Colors.red;
            } else if (!isSelected && isCorrect) {
              // Not selected but correct answer
              backgroundColor = Colors.green.withValues(alpha: 0.05);
              borderColor = Colors.green.withValues(alpha: 0.5);
              textColor = Colors.green.withValues(alpha: 0.8);
            } else {
              // Default style
              backgroundColor = theme.colorScheme.surface;
              borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
              textColor = theme.colorScheme.onSurface;
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected || isCorrect
                          ? (isCorrect ? Colors.green : Colors.red)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected || isCorrect
                            ? (isCorrect ? Colors.green : Colors.red)
                            : theme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        optionLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected || isCorrect
                              ? Colors.white
                              : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      answerOption,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Symbols.check_circle,
                      size: 16,
                      color: textColor,
                    ),
                  ],
                  if (!isSelected && isCorrect) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Symbols.lightbulb,
                      size: 16,
                      color: textColor,
                    ),
                  ],
                ],
              ),
            );
          }),
          if (safeQuestion.explanation.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
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
                        Symbols.info,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.exam.results.explanation,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    safeQuestion.explanation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<SubmitAnswerResult>('answer', answer))
      ..add(DiagnosticsProperty<Exam>('exam', exam));
  }
}
