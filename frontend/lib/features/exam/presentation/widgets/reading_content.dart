import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import 'exam_question_list.dart';
import 'image_viewer_widget.dart';

class ReadingContent extends ConsumerWidget {
  const ReadingContent({
    super.key,
    required this.content,
  });

  final Content content;
  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
              Symbols.menu_book,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.t.exam.reading.comprehension,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.article,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t.exam.parts.readingPassage,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content.description.isNotEmpty)
              Text(
                content.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.warning_amber,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t.exam.parts.noReadingPassage,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ...() {
        final questionsWithImages = content.questions.where(
          (final q) => q.imageUrl != null && q.imageUrl!.isNotEmpty,
        );

        if (questionsWithImages.isEmpty) {
          return [const SizedBox.shrink()];
        }

        return [
          ...questionsWithImages.map(
            (final question) => _QuestionContent(
              question: question,
              content: content,
            ),
          ),
        ];
      }(),
      ExamQuestionList(questions: content.questions),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Content>('content', content));
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    required this.question,
    required this.content,
  });

  final Question question;

  final Content content;

  @override
  Widget build(final BuildContext context) {
    final message = context.t.exam.parts.readingPassageImage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ImageViewerWidget(
        imageUrl: question.imageUrl!,
        title: '$message ${content.questions.indexOf(question) + 1}',
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Question>('question', question))
      ..add(DiagnosticsProperty<Content>('content', content));
  }
}
