import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import 'content_tab_view.dart';
import 'exam_progress_bar.dart';

class ExamContent extends ConsumerWidget {
  const ExamContent({
    super.key,
    required this.exam,
  });

  final Exam exam;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final listeningContents = <Content>[];
    final readingContents = <Content>[];

    for (final part in exam.parts) {
      for (final content in part.contents) {
        if (part.partId.isOdd) {
          listeningContents.add(content);
        } else {
          readingContents.add(content);
        }
      }
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    _ListeningTab(
                      listeningContents: listeningContents,
                    ),
                    _ReadingTab(
                      readingContents: readingContents,
                    ),
                  ],
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                ExamProgressBar(exam: exam),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ContentTabView(
                  contents: listeningContents,
                  icon: Symbols.headphones,
                  color: Colors.blue,
                  exam: exam,
                ),
                ContentTabView(
                  contents: readingContents,
                  icon: Symbols.menu_book,
                  color: Colors.green,
                  exam: exam,
                ),
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
    properties.add(DiagnosticsProperty<Exam>('exam', exam));
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({
    super.key,
    required this.readingContents,
  });

  final List<Content> readingContents;

  @override
  Widget build(final BuildContext context) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Symbols.menu_book),
        const SizedBox(width: 8),
        Text(
          '${context.t.exam.modules.reading} (${readingContents.length})',
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<Content>('readingContents', readingContents),
    );
  }
}

class _ListeningTab extends StatelessWidget {
  const _ListeningTab({
    required this.listeningContents,
  });

  final List<Content> listeningContents;

  @override
  Widget build(final BuildContext context) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Symbols.headphones),
        const SizedBox(width: 8),
        Text(
          '${context.t.exam.modules.listening} (${listeningContents.length})',
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<Content>('listeningContents', listeningContents),
    );
  }
}

class ExamLoadingShimmer extends StatelessWidget {
  const ExamLoadingShimmer({super.key});

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder:
        (final context, final index) => Shimmer(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    3,
                    (final index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

class ExamErrorContent extends StatelessWidget {
  const ExamErrorContent({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final void Function() onRetry;

  @override
  Widget build(final BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Symbols.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          context.t.exam.error.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: Text(context.t.exam.error.retry),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Object>('error', error))
      ..add(ObjectFlagProperty<void Function()>.has('onRetry', onRetry));
  }
}
