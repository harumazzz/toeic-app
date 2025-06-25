import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../providers/attempt_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/user_answers_provider.dart';
import '../widgets/exam_content.dart';

class ExamScreen extends HookConsumerWidget {
  const ExamScreen({
    super.key,
    required this.examId,
  });

  final int examId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final examState = ref.watch(examNotifierProvider);
    final attemptState = ref.watch(attemptNotifierProvider);

    // Listen to attempt state changes
    ref.listen<AttemptState>(
      attemptNotifierProvider,
      (final previous, final next) {
        switch (next) {
          case AttemptStarted():
            ToastService.success(
              context: context,
              message: 'Exam attempt started successfully',
            );
            break;
          case AttemptError(:final message):
            ToastService.error(
              context: context,
              message: message,
            );
            break;
          default:
            break;
        }
      },
    );

    useEffect(() {
      Future.microtask(() async {
        await ref.read(examNotifierProvider.notifier).loadExam(examId);
      });
      return null;
    }, [examId]);

    // Start exam attempt when exam is loaded
    useEffect(() {
      if (examState is ExamLoaded && attemptState is AttemptInitial) {
        Future.microtask(() async {
          await ref
              .read(attemptNotifierProvider.notifier)
              .startExamAttempt(examId);
        });
      }
      return null;
    }, [examState, attemptState]);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.exam.title),
      ),
      body: switch (examState) {
        ExamInitial() => Center(
          child: Text(context.t.exam.states.initializing),
        ),
        ExamLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        final ExamLoaded state => ExamContent(exam: state.exam),
        ExamError() => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.t.exam.error.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () => ref
                        .read(examNotifierProvider.notifier)
                        .loadExam(examId),
                child: Text(context.t.exam.error.retry),
              ),
            ],
          ),
        ),
      },
      floatingActionButton:
          examState is ExamLoaded
              ? Consumer(
                builder: (final context, final ref, final child) {
                  final userAnswers = ref.watch(userAnswersProvider);
                  final exam = examState.exam;
                  final isCompleted = userAnswers.length == exam.totalQuestions;

                  return FloatingActionButton.extended(
                    onPressed:
                        isCompleted
                            ? () {
                              _showSubmitDialog(
                                context,
                                ref,
                                userAnswers,
                                exam.totalQuestions,
                              );
                            }
                            : null,
                    backgroundColor:
                        isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                    foregroundColor: Colors.white,
                    icon: Icon(
                      isCompleted ? Symbols.check_circle : Symbols.pending,
                    ),
                    label: Text(
                      isCompleted
                          ? context.t.exam.submission.submitExam
                          : context.t.exam.submission.completeAllQuestions,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              )
              : null,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('examId', examId));
  }

  void _showSubmitDialog(
    final BuildContext context,
    final WidgetRef ref,
    final Map<int, String> userAnswers,
    final int totalQuestions,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (final context) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Symbols.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(context.t.exam.submission.submitConfirmTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.exam.submission.completedAllQuestions(
                    totalQuestions: totalQuestions,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Symbols.info,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t.exam.submission.answersWillBeGraded,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.t.exam.submission.reviewAnswers),
              ),
              ElevatedButton(
                onPressed: () async {
                  // TODO(dev): Submit answers to backend
                  Navigator.of(context).pop();
                  await _showSubmissionSuccess(
                    context,
                    userAnswers.length,
                    totalQuestions,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.t.exam.submission.submitExam),
              ),
            ],
          ),
    );
  }

  Future<void> _showSubmissionSuccess(
    final BuildContext context,
    final int answeredQuestions,
    final int totalQuestions,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (final context) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Symbols.celebration,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(context.t.exam.submission.successTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Symbols.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t.exam.submission.successMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.t.exam.submission.answeredQuestions(
                    answered: answeredQuestions,
                    total: totalQuestions,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(context.t.exam.submission.backToHome),
              ),
            ],
          ),
    );
  }
}
