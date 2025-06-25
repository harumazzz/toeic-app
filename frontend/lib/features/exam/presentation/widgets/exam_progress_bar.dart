import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/entities/exam.dart';
import '../providers/user_answers_provider.dart';

class ExamProgressBar extends ConsumerWidget {
  const ExamProgressBar({
    super.key,
    required this.exam,
  });

  final Exam exam;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAnswers = ref.watch(userAnswersProvider);
    final totalQuestions = exam.totalQuestions;
    final answeredQuestions = userAnswers.length;
    final progress =
        totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$answeredQuestions / $totalQuestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0
                ? 'All questions completed! 🎉'
                : '${(progress * 100).toInt()}% completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  progress == 1.0
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: progress == 1.0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Exam>('exam', exam));
  }
}
