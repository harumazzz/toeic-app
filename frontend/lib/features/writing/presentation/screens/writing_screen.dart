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
import '../../domain/entities/writing_prompt.dart';
import '../providers/user_writing_provider.dart';
import '../providers/writing_prompt_provider.dart';
import '../widgets/writing_empty_state_widget.dart';
import '../widgets/writing_error_widget.dart';
import '../widgets/writing_history_card.dart';
import '../widgets/writing_prompt_card.dart';
import 'writing_view_screen.dart';

class WritingScreen extends HookConsumerWidget {
  const WritingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedIndex = useState(0);
    final authState = ref.watch(authControllerProvider);
    final writingPromptState = ref.watch(writingPromptControllerProvider);
    final userWritingsState = ref.watch(userWritingsByUserControllerProvider);
    final isInitialized = useRef(false);
    final theme = Theme.of(context);
    useEffect(() {
      if (!isInitialized.value) {
        isInitialized.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref
              .read(writingPromptControllerProvider.notifier)
              .loadWritingPrompts();

          if (authState is AuthAuthenticated) {
            await ref
                .read(userWritingsByUserControllerProvider.notifier)
                .loadUserWritingsByUserId(authState.user.id);
          }
        });
      }
      return null;
    }, const []);

    useEffect(() {
      if (authState is AuthAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(userWritingsByUserControllerProvider.notifier)
              .loadUserWritingsByUserId(authState.user.id);
        });
      }
      return null;
    }, [authState]);

    if (authState is! AuthAuthenticated) {
      return WritingEmptyStateWidget(
        title: context.t.writing.noWritingsYet,
        message: context.t.writing.mustBeLoggedIn,
        icon: Symbols.login,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t.writing.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: IndexedStack(
        index: selectedIndex.value,
        children: [
          switch (writingPromptState) {
            WritingPromptInitial() => WritingEmptyStateWidget(
              title: context.t.writing.readyToWrite,
              message: context.t.writing.tapRefreshToLoadPrompts,
              icon: Symbols.article,
            ),
            WritingPromptLoading() => const _ShimmerLoading(),
            WritingPromptError(message: final message) => WritingErrorWidget(
              message: message,
            ),
            WritingPromptLoaded(prompts: final prompts) =>
              prompts.isEmpty
                  ? WritingEmptyStateWidget(
                    title: context.t.writing.noPromptsAvailable,
                    message: context.t.writing.noPromptsAtMoment,
                    icon: Symbols.article,
                  )
                  : _WritingList(
                    prompts: prompts,
                  ),
          },
          switch (userWritingsState) {
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
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: writings.length,
                    itemBuilder:
                        (final context, final index) => WritingHistoryCard(
                          writing: writings[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (final context) => WritingViewScreen(
                                      writing: writings[index],
                                    ),
                              ),
                            );
                          },
                          onDelete: () async {
                            final success = await ref
                                .read(
                                  userWritingsByUserControllerProvider.notifier,
                                )
                                .deleteWriting(
                                  writings[index].id,
                                  authState.user.id,
                                );

                            if (context.mounted) {
                              if (success) {
                                ToastService.success(
                                  context: context,
                                  message: 'Writing deleted successfully',
                                );
                              } else {
                                ToastService.error(
                                  context: context,
                                  message: 'Failed to delete writing',
                                );
                              }
                            }
                          },
                        ),
                  ),
          },
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await const PracticeWritingRoute().push(context);
        },
        child: const Icon(Symbols.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.value,
        onDestinationSelected: (final index) async {
          selectedIndex.value = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.edit_note),
            label: context.t.writing.writingPrompts,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.history),
            label: context.t.writing.myWritings,
          ),
        ],
      ),
    );
  }
}

class _WritingList extends StatelessWidget {
  const _WritingList({required this.prompts});

  final List<WritingPrompt> prompts;

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: prompts.length,
    itemBuilder:
        (final context, final index) => WritingPromptCard(
          prompt: prompts[index],
        ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<WritingPrompt>('prompts', prompts));
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(final BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder:
        (final context, final index) => Shimmer(
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
