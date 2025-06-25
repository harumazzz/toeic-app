import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import 'exam_content_item.dart';

class ExamPartHeaderWidget extends StatelessWidget {
  const ExamPartHeaderWidget({
    super.key,
    required this.part,
  });

  final Part part;

  @override
  Widget build(final BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.t.exam.parts.part} ${part.partId}: ${part.title}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('${context.t.exam.details.partId}: ${part.partId}'),
          _NumberOfContent(
            part: part,
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Part>('part', part));
  }
}

class _NumberOfContent extends StatelessWidget {
  const _NumberOfContent({required this.part});

  final Part part;

  @override
  Widget build(final BuildContext context) => Text(
    '${context.t.exam.details.numberOfContents}: ${part.contents.length}',
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Part>('part', part));
  }
}

class ExamPartContentListWidget extends StatelessWidget {
  const ExamPartContentListWidget({
    super.key,
    required this.contents,
    required this.showContentHeaders,
  });

  final List<Content> contents;

  final bool showContentHeaders;

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: contents.length,
    itemBuilder: (final context, final index) {
      final content = contents[index];
      return Container(
        margin: EdgeInsets.only(
          bottom: index < contents.length - 1 ? 16 : 0,
        ),
        child: ExamContentItem(
          content: content,
          showContentHeader: showContentHeaders,
        ),
      );
    },
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Content>('contents', contents))
      ..add(
        DiagnosticsProperty<bool>('showContentHeaders', showContentHeaders),
      );
  }
}

class ExamPartContent extends ConsumerWidget {
  const ExamPartContent({
    super.key,
    required this.part,
  });

  final Part part;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final hasMultipleContents = part.contents.length > 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMultipleContents) ...[
            ExamPartHeaderWidget(part: part),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: ExamPartContentListWidget(
              contents: part.contents,
              showContentHeaders: hasMultipleContents,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Part>('part', part));
  }
}
