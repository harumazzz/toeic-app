import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/services/word_notification_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../progress/domain/entities/progress.dart';
import '../../../progress/presentation/providers/review_progress_provider.dart';
import '../../../settings/services/notification_scheduler_service.dart';
import '../providers/word_provider.dart';
import '../widgets/flashcard_widget.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final reviewProgressState = ref.watch(reviewProgressNotifierProvider);
    final wordState = ref.watch(wordControllerProvider);
    final currentIndex = useState(0);
    final offset = useState(0);
    final hasRequestedPermission = useState(false);

    useEffect(() {
      Future.microtask(() async {
        await ref
            .read(reviewProgressNotifierProvider.notifier)
            .loadReviewProgress(
              limit: 10,
              offset: offset.value,
            );
        offset.value += 10;
        if (!hasRequestedPermission.value) {
          hasRequestedPermission.value = true;
          if (context.mounted) {
            await _requestNotificationPermissions(context);
          }
        }
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.modules.learnWords),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Symbols.notifications_active),
            onPressed: () => _showNotificationMenu(context, ref, wordState),
            tooltip: 'Schedule word notifications',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: switch (reviewProgressState) {
                ReviewProgressInitial() => const SizedBox.shrink(),
                ReviewProgressLoading() => const _ReviewProgressLoadingView(),
                final ReviewProgressLoaded state =>
                  state.progress.isEmpty
                      ? const SizedBox.shrink()
                      : _ProgressHeader(
                          currentIndex: currentIndex.value,
                          totalCards: state.progress.length,
                        ),
                ReviewProgressError() => const SizedBox.shrink(),
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: switch (reviewProgressState) {
                  ReviewProgressInitial() => const SizedBox.shrink(),
                  ReviewProgressLoading() => const _ReviewProgressLoadingView(),
                  final ReviewProgressLoaded state =>
                    state.progress.isEmpty
                        ? const _EmptyStateView()
                        : _FlashcardSwiper(
                            progress: state.progress,
                            onIndexChanged: (final index) {
                              currentIndex.value = index;
                            },
                          ),
                  final ReviewProgressError state => _ReviewProgressErrorView(
                    message: state.message,
                    onRetry: () async {
                      await ref
                          .read(reviewProgressNotifierProvider.notifier)
                          .loadReviewProgress(
                            limit: 10,
                            offset: offset.value,
                          );
                      offset.value += 10;
                    },
                  ),
                },
              ),
            ),
          ],
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 6,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 6,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentIndex + 1}/$totalCards',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${((currentIndex + 1) / totalCards * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
    itemBuilder: (final context, final index) => FlashcardWidget(
      word: progress[index].word,
      frontBuilder: (final context, final word) => FrontSideCard(
        word: word,
      ),
      backBuilder: (final context, final word) => BackSideCard(
        word: word,
      ),
    ),
    itemHeight: MediaQuery.of(context).size.height * 0.55,
    viewportFraction: 0.85,
    scale: 0.85,
    pagination: SwiperPagination(
      margin: const EdgeInsets.only(bottom: 8),
      builder: DotSwiperPaginationBuilder(
        activeColor: Theme.of(context).colorScheme.primary,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        size: 6,
        activeSize: 8,
        space: 4,
      ),
    ),
    control: SwiperControl(
      iconPrevious: Symbols.chevron_left,
      iconNext: Symbols.chevron_right,
      color: Theme.of(context).colorScheme.primary,
      disableColor: Theme.of(
        context,
      ).colorScheme.outline.withValues(alpha: 0.3),
      size: 20,
      padding: const EdgeInsets.all(8),
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
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.t.modules.addWordsToStartLearning,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
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
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Symbols.refresh, size: 18),
            label: Text(context.t.common.retry),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerContainer(
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ShimmerContainer(
                interval: const Duration(milliseconds: 1000),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ShimmerContainer(
                interval: const Duration(milliseconds: 1200),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShimmerContainer(
                    interval: const Duration(milliseconds: 900),
                    child: Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  _ShimmerContainer(
                    interval: const Duration(milliseconds: 1100),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  _ShimmerContainer(
                    interval: const Duration(milliseconds: 1300),
                    child: Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  const _ShimmerContainer({
    required this.child,
    this.interval = const Duration(milliseconds: 800),
  });

  final Widget child;
  final Duration interval;

  @override
  Widget build(final BuildContext context) => Shimmer(
    interval: interval,
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    child: child,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Widget>('child', child))
      ..add(DiagnosticsProperty<Duration>('interval', interval));
  }
}

Future<void> _requestNotificationPermissions(final BuildContext context) async {
  final hasPermission = await NotificationSchedulerService.requestPermissions();

  if (!hasPermission && context.mounted) {
    ToastService.error(
      context: context,
      message: 'Permission to send notifications was denied',
    );
  }
}

void _showNotificationMenu(
  final BuildContext context,
  final WidgetRef ref,
  final WordState wordState,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (final context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (final context, final scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Symbols.notifications_active,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Word Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Notification options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _NotificationOption(
                    icon: Symbols.schedule,
                    title: context.t.learning.scheduleDailyLearning,
                    description: 'Get daily reminders to learn new words',
                    onTap: () => _scheduleNotification(context, ref, 'daily'),
                  ),
                  const SizedBox(height: 12),
                  _NotificationOption(
                    icon: Symbols.repeat,
                    title: context.t.learning.scheduleMultipleReminders,
                    description: 'Get reminders multiple times per day',
                    onTap: () =>
                        _scheduleNotification(context, ref, 'multiple'),
                  ),
                  const SizedBox(height: 12),
                  _NotificationOption(
                    icon: Symbols.star,
                    title: context.t.learning.motivationalNotifications,
                    description: 'Get encouraging messages to keep learning',
                    onTap: () =>
                        _scheduleNotification(context, ref, 'motivational'),
                  ),
                  const SizedBox(height: 12),
                  _NotificationOption(
                    icon: Symbols.cancel,
                    title: context.t.learning.cancelAllNotifications,
                    description: 'Stop all scheduled word notifications',
                    onTap: () => _cancelAllNotifications(context, ref),
                    isDestructive: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _scheduleNotification(
  final BuildContext context,
  final WidgetRef ref,
  final String type,
) async {
  Navigator.of(context).pop(); // Close bottom sheet

  try {
    switch (type) {
      case 'daily':
        // Schedule basic daily notification at default time (9 AM)
        await NotificationSchedulerService.scheduleWordNotifications(
          words: const [], // Using empty words list for basic notification
          frequency: NotificationFrequency.daily,
          preferredHour: 9,
        );
        break;
      case 'multiple':
        // Schedule multiple notifications per day
        await NotificationSchedulerService.scheduleWordNotifications(
          words: const [], // Using empty words list for basic notification
          frequency: NotificationFrequency.twiceDaily,
          preferredHour: 9,
        );
        break;
      case 'motivational':
        await NotificationSchedulerService.scheduleMotivationalNotifications();
        break;
    }

    if (context.mounted) {
      ToastService.success(
        context: context,
        message: 'Notifications scheduled successfully',
      );
    }
  } catch (e) {
    debugPrint(e.toString());
    if (context.mounted) {
      ToastService.error(
        context: context,
        message: 'Failed to schedule notifications',
      );
    }
  }
}

Future<void> _cancelAllNotifications(
  final BuildContext context,
  final WidgetRef ref,
) async {
  Navigator.of(context).pop(); // Close bottom sheet

  try {
    await NotificationSchedulerService.cancelAllWordNotifications();

    if (context.mounted) {
      ToastService.success(
        context: context,
        message: 'All notifications cancelled',
      );
    }
  } catch (e) {
    if (context.mounted) {
      ToastService.error(
        context: context,
        message: 'Failed to cancel notifications',
      );
    }
  }
}

class _NotificationOption extends StatelessWidget {
  const _NotificationOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right,
                color: colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('title', title))
      ..add(StringProperty('description', description))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(DiagnosticsProperty<bool>('isDestructive', isDestructive));
  }
}
