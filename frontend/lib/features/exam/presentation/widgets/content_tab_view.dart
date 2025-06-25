import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/entities/exam.dart';
import 'exam_part_content.dart';

class ContentTabView extends ConsumerWidget {
  const ContentTabView({
    super.key,
    required this.contents,
    required this.icon,
    required this.color,
    required this.exam,
  });

  final List<Content> contents;
  final IconData icon;
  final Color color;
  final Exam exam;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: contents.length,
      child: Column(
        children: [
          ColoredBox(
            color: color.withValues(alpha: 0.1),
            child: TabBar(
              isScrollable: true,
              tabs: [
                ...contents.asMap().entries.map((final entry) {
                  final index = entry.key;
                  final content = entry.value;
                  return Tab(
                    text: 'Content ${index + 1} (${content.questions.length})',
                  );
                }),
              ],
              indicatorColor: color,
              labelColor: color,
              unselectedLabelColor: color.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ...contents.map((final content) {
                  final part = exam.parts.firstWhere(
                    (final p) => p.contents.contains(content),
                  );
                  return ExamPartContent(
                    part: Part(
                      partId: part.partId,
                      title: part.title,
                      contents: [content],
                    ),
                  );
                }),
              ],
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
      ..add(IterableProperty<Content>('contents', contents))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(DiagnosticsProperty<Exam>('exam', exam));
  }
}
