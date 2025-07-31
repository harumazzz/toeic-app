import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/exam.dart';
import '../providers/exams_provider.dart';
import '../widgets/exam_card.dart';

class PracticeScreen extends HookConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final examsState = ref.watch(examsNotifierProvider);
    final scrollController = useScrollController();
    final isLoaded = useState(false);

    useEffect(() {
      Future<void> onScroll() async {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          await ref.read(examsNotifierProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    useEffect(() {
      Future.microtask(() async {
        await ref.read(examsNotifierProvider.notifier).loadMore();
        isLoaded.value = true;
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.page.practice),
      ),
      body: RefreshIndicator(
        onRefresh:
            () async => ref.read(examsNotifierProvider.notifier).refresh(),
        child: switch (examsState) {
          ExamInitial() => const _LoadingShimmer(),
          ExamLoading(exams: final exams) =>
            !isLoaded.value
                ? const _LoadingShimmer()
                : _ExamsList(
                  exams: exams,
                  scrollController: scrollController,
                  isLoading: true,
                ),
          ExamLoaded(exams: final exams, hasMore: final hasMore) => _ExamsList(
            exams: exams,
            scrollController: scrollController,
            isLoading: false,
            hasMore: hasMore,
          ),
          ExamError(exams: final exams, message: final message) =>
            exams.isEmpty
                ? _ErrorView(
                  message: message,
                  onRetry:
                      () async =>
                          ref.read(examsNotifierProvider.notifier).refresh(),
                )
                : _ExamsList(
                  exams: exams,
                  scrollController: scrollController,
                  isLoading: false,
                  errorMessage: message,
                ),
        },
      ),
    );
  }
}

class _ExamsList extends StatelessWidget {
  const _ExamsList({
    required this.exams,
    required this.scrollController,
    required this.isLoading,
    this.hasMore = false,
    this.errorMessage,
  });

  final List<Exam> exams;
  final ScrollController scrollController;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  @override
  Widget build(final BuildContext context) => ListView.builder(
    controller: scrollController,
    padding: const EdgeInsets.all(12),
    itemCount: exams.length + (hasMore ? 1 : 0),
    itemBuilder: (final context, final index) {
      if (index == exams.length) {
        return const _LoadingShimmer();
      }
      final exam = exams[index];
      return ExamCard(exam: exam);
    },
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Exam>('exams', exams))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
        ),
      )
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<bool>('hasMore', hasMore))
      ..add(StringProperty('errorMessage', errorMessage));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final void Function() onRetry;

  @override
  Widget build(final BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: Text(context.t.common.retry),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(ObjectFlagProperty<void Function()>.has('onRetry', onRetry));
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder:
          (final context, final index) => _ShimmerContainer(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: shimmerColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: shimmerColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  const _ShimmerContainer({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => Shimmer(
    interval: const Duration(seconds: 1),
    child: child,
  );
}
