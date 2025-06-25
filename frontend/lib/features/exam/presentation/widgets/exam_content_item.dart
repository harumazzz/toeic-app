import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import 'exam_question_list.dart';
import 'listening_content.dart';
import 'reading_content.dart';

class ExamContentItem extends ConsumerWidget {
  const ExamContentItem({
    super.key,
    required this.content,
    this.showContentHeader = true,
  });

  final Content content;
  final bool showContentHeader;
  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showContentHeader) ...[
            Row(
              children: [
                Icon(
                  content.type.toLowerCase().contains('listening')
                      ? Symbols.headphones
                      : Symbols.menu_book,
                  color:
                      content.type.toLowerCase().contains('listening')
                          ? Colors.blue
                          : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.t.exam.parts.content}: ${content.contentId}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text('${context.t.exam.details.type}: ${content.type}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${context.t.exam.details.description}: ${content.description}',
            ),
            _NumberOfQuestions(
              content: content,
            ),
            const SizedBox(height: 16),
          ],
          if (content.type.toLowerCase().contains('reading'))
            ReadingContent(content: content)
          else if (content.type.toLowerCase().contains('listening'))
            ListeningContent(content: content)
          else
            ExamQuestionList(questions: content.questions),
        ],
      ),
    ),
  );
  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Content>('content', content))
      ..add(
        FlagProperty(
          'showContentHeader',
          value: showContentHeader,
          ifTrue: 'showing header',
          ifFalse: 'hiding header',
        ),
      );
  }
}

class _NumberOfQuestions extends StatelessWidget {
  const _NumberOfQuestions({super.key, required this.content});

  final Content content;

  @override
  Widget build(final BuildContext context) => Text(
    '${context.t.exam.details.numberOfQuestions}: ${content.questions.length}',
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Content>('content', content));
  }
}
