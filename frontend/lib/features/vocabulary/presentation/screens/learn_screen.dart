import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../i18n/strings.g.dart';
import '../../../progress/domain/entities/progress.dart';
import '../../../progress/presentation/providers/review_progress_provider.dart';
import '../widgets/flashcard_widget.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final reviewProgressState = ref.watch(reviewProgressNotifierProvider);
    final currentIndex = useState(0);
    final currentPage = useState(0);

    useEffect(() {
      Future.microtask(() async {
        await ref
            .read(reviewProgressNotifierProvider.notifier)
            .loadReviewProgress(
              limit: 10,
              offset: currentPage.value,
            );
      });
      currentPage.value++;
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.modules.learnWords),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: switch (reviewProgressState) {
            ReviewProgressInitial() => const SizedBox.shrink(),
            ReviewProgressLoading() => const _ReviewProgressLoadingView(),
            final ReviewProgressLoaded state =>
              state.progress.isEmpty
                  ? const _EmptyStateView()
                  : Column(
                    children: [
                      _ProgressHeader(
                        currentIndex: currentIndex.value,
                        totalCards: state.progress.length,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _FlashcardSwiper(
                          progress: state.progress,
                          onIndexChanged: (final index) {
                            currentIndex.value = index;
                          },
                        ),
                      ),
                    ],
                  ),
            final ReviewProgressError state => _ReviewProgressErrorView(
              message: state.message,
              onRetry: () async {
                await ref
                    .read(reviewProgressNotifierProvider.notifier)
                    .loadReviewProgress(
                      limit: 10,
                      offset: currentPage.value,
                    );
                currentPage.value++;
              },
            ),
          },
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.currentIndex,
    required this.totalCards,
  });

  final int currentIndex;
  final int totalCards;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / totalCards,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentIndex + 1}/$totalCards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${((currentIndex + 1) / totalCards * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('currentIndex', currentIndex))
      ..add(IntProperty('totalCards', totalCards));
  }
}

class _FlashcardSwiper extends StatelessWidget {
  const _FlashcardSwiper({
    required this.progress,
    required this.onIndexChanged,
  });

  final List<WordProgress> progress;

  final void Function(int) onIndexChanged;

  @override
  Widget build(final BuildContext context) => Swiper(
    onIndexChanged: onIndexChanged,
    itemCount: progress.length,
    itemBuilder:
        (final context, final index) => FlashcardWidget(
          word: progress[index].word,
          frontBuilder:
              (final context, final word) => FrontSideCard(
                word: word,
              ),
          backBuilder:
              (final context, final word) => BackSideCard(
                word: word,
              ),
        ),
    itemHeight: MediaQuery.of(context).size.height * 0.7,
    pagination: SwiperPagination(
      builder: DotSwiperPaginationBuilder(
        activeColor: Theme.of(context).colorScheme.primary,
        color: Theme.of(context).colorScheme.outline,
        size: 8,
        activeSize: 12,
      ),
    ),
    control: SwiperControl(
      color: Theme.of(context).colorScheme.primary,
      disableColor: Theme.of(context).colorScheme.outline,
      size: 24,
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<WordProgress>('progress', progress))
      ..add(
        ObjectFlagProperty<void Function(int p1)>.has(
          'onIndexChanged',
          onIndexChanged,
        ),
      );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(final BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.school,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t.modules.noWordsToLearn,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.t.modules.addWordsToStartLearning,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ReviewProgressErrorView extends StatelessWidget {
  const _ReviewProgressErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final void Function() onRetry;

  @override
  Widget build(final BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Symbols.refresh),
            label: Text(context.t.common.retry),
          ),
        ],
      ),
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

class _ReviewProgressLoadingView extends StatelessWidget {
  const _ReviewProgressLoadingView();

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder:
        (final context, final index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
