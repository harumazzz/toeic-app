import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_writing.dart';
import '../providers/user_writing_provider.dart';
import '../widgets/writing_empty_state_widget.dart';
import '../widgets/writing_error_widget.dart';
import '../widgets/writing_history_card.dart';
import 'writing_view_screen.dart';

class WritingScreen extends HookConsumerWidget {
  const WritingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userWritingsState = ref.watch(userWritingsByUserControllerProvider);
    final isInitialized = useRef(false);
    final theme = Theme.of(context);

    useEffect(() {
      if (!isInitialized.value) {
        isInitialized.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (authState is AuthAuthenticated) {
            await ref
                .read(userWritingsByUserControllerProvider.notifier)
                .loadUserWritingsByUserId(authState.user.id);
          }
        });
      }
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.writing.myWritings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: () async {
              if (authState is AuthAuthenticated) {
                await ref
                    .read(userWritingsByUserControllerProvider.notifier)
                    .loadUserWritingsByUserId(authState.user.id);
              }
            },
          ),
        ],
      ),
      body: switch (userWritingsState) {
        UserWritingInitial() => WritingEmptyStateWidget(
          title: context.t.writing.noWritingsYet,
          message: context.t.writing.writingsWillAppearHere,
          icon: Symbols.article,
        ),
        UserWritingLoading() => const _ShimmerLoading(),
        UserWritingError(message: final message) => WritingErrorWidget(
          message: message,
        ),
        UserWritingLoaded(writings: final writings) =>
          writings.isEmpty
              ? WritingEmptyStateWidget(
                  title: context.t.writing.noWritingsYet,
                  message: context.t.writing.writingsWillAppearHere,
                  icon: Symbols.article,
                )
              : _MyWritingsList(
                  userWritings: writings,
                  onDelete: (final writingId) async {
                    if (authState is AuthAuthenticated) {
                      final success = await ref
                          .read(userWritingsByUserControllerProvider.notifier)
                          .deleteWriting(writingId, authState.user.id);

                      if (context.mounted) {
                        if (success) {
                          ToastService.success(
                            context: context,
                            message:
                                t.writingAnalysis.writingDeletedSuccessfully,
                          );
                        } else {
                          ToastService.error(
                            context: context,
                            message: t.writingAnalysis.failedToDeleteWriting,
                          );
                        }
                      }
                    }
                  },
                ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await const PracticeWritingRoute().push(context);
        },
        child: const Icon(Symbols.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MyWritingsList extends StatelessWidget {
  const _MyWritingsList({
    required this.userWritings,
    required this.onDelete,
  });

  final List<UserWriting> userWritings;
  final Function(int) onDelete;

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: userWritings.length,
    itemBuilder: (final context, final index) {
      final writing = userWritings[index];
      return WritingHistoryCard(
        writing: writing,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (final context) => WritingViewScreen(
                writing: writing,
              ),
            ),
          );
        },
        onDelete: () => onDelete(writing.id),
      );
    },
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<UserWriting>('userWritings', userWritings))
      ..add(ObjectFlagProperty<Function(int)>.has('onDelete', onDelete));
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder: (final context, final index) => Shimmer(
      duration: const Duration(seconds: 2),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
