import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import '../providers/user_answers_provider.dart';
import 'audio_player_widget.dart';
import 'image_viewer_widget.dart';

class ExamQuestionList extends ConsumerWidget {
  const ExamQuestionList({
    super.key,
    required this.questions,
  });

  final List<Question> questions;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...questions.asMap().entries.map((final entry) {
        final index = entry.key;
        final question = entry.value;
        return _QuestionCard(
          question: question,
          index: index,
        );
      }),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Question>('questions', questions));
  }
}

class _QuestionCard extends ConsumerWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
  });

  final Question question;
  final int index;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedAnswer = ref.watch(getAnswerProvider(question.questionId));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selectedAnswer != null
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
          width: selectedAnswer != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionHeader(
            question: question,
            index: index,
            selectedAnswer: selectedAnswer,
          ),
          _QuestionMedia(
            question: question,
            index: index,
          ),
          _AnswerOptions(
            question: question,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Question>('question', question))
      ..add(IntProperty('index', index));
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.question,
    required this.index,
    required this.selectedAnswer,
  });

  final Question question;
  final int index;
  final String? selectedAnswer;

  @override
  Widget build(final BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:
          selectedAnswer != null
              ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                selectedAnswer != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            question.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (selectedAnswer != null)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Symbols.check,
              color: Colors.white,
              size: 16,
            ),
          ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Question>('question', question))
      ..add(IntProperty('index', index))
      ..add(StringProperty('selectedAnswer', selectedAnswer));
  }
}

class _QuestionMedia extends StatelessWidget {
  const _QuestionMedia({
    required this.question,
    required this.index,
  });

  final Question question;
  final int index;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty) ...[
          AudioPlayerWidget(
            audioUrl: question.mediaUrl!,
            title: context.t.exam.question.audio.replaceAll(
              '{}',
              (index + 1).toString(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          ImageViewerWidget(
            imageUrl: question.imageUrl!,
            title: context.t.exam.question.image.replaceAll(
              '{}',
              (index + 1).toString(),
            ),
          ),
        ],
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Question>('question', question))
      ..add(IntProperty('index', index));
  }
}

class _AnswerOptions extends ConsumerWidget {
  const _AnswerOptions({
    required this.question,
  });

  final Question question;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        ...question.possibleAnswers.asMap().entries.map((final answerEntry) {
          final answerIndex = answerEntry.key;
          final answer = answerEntry.value;
          final answerLetter = String.fromCharCode(65 + answerIndex);

          return _AnswerOption(
            question: question,
            answer: answer,
            answerLetter: answerLetter,
          );
        }),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Question>('question', question));
  }
}

class _AnswerOption extends ConsumerWidget {
  const _AnswerOption({
    required this.question,
    required this.answer,
    required this.answerLetter,
  });

  final Question question;
  final String answer;
  final String answerLetter;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedAnswer = ref.watch(getAnswerProvider(question.questionId));
    final isSelected = selectedAnswer == answerLetter;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref
                .read(userAnswersProvider.notifier)
                .setAnswer(
                  question.questionId,
                  answerLetter,
                );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      answerLetter,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    answer,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                ),
              ],
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
      ..add(DiagnosticsProperty<Question>('question', question))
      ..add(StringProperty('answer', answer))
      ..add(StringProperty('answerLetter', answerLetter));
  }
}
