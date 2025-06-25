import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../utils/writing_draft_manager.dart';

class DraftsManagementScreen extends HookWidget {
  const DraftsManagementScreen({super.key});
  @override
  Widget build(final BuildContext context) {
    final drafts = useState<List<DraftInfo>>([]);
    final isLoading = useState(false);

    Future<void> loadDrafts() async {
      isLoading.value = true;
      try {
        final loadedDrafts = await WritingDraftManager.getAllDrafts();
        drafts.value = loadedDrafts;
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: context.t.writing.drafts.failedToLoad,
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadDrafts();
      return null;
    }, []);

    Future<void> deleteDraft(final DraftInfo draft) async {
      try {
        await WritingDraftManager.clearDraft(draft.promptId);
        await loadDrafts();
        if (context.mounted) {
          ToastService.success(
            context: context,
            message: context.t.writing.drafts.draftCleared,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: context.t.writing.drafts.failedToDelete,
          );
        }
      }
    }

    Future<void> clearAllDrafts() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (final context) => AlertDialog(
              title: Text(context.t.writing.drafts.clearAll),
              content: Text(context.t.writing.drafts.confirmClearAll),
              actions: [
                TextButton(
                  onPressed: () async => Navigator.of(context).pop(false),
                  child: Text(context.t.common.cancel),
                ),
                TextButton(
                  onPressed: () async => Navigator.of(context).pop(true),
                  child: Text(context.t.common.confirm),
                ),
              ],
            ),
      );

      if (confirmed != null && confirmed == true) {
        try {
          await WritingDraftManager.clearAllDrafts();
          await loadDrafts();
          if (context.mounted) {
            ToastService.success(
              context: context,
              message: context.t.writing.drafts.allDraftsCleared,
            );
          }
        } catch (e) {
          if (context.mounted) {
            ToastService.error(
              context: context,
              message: context.t.writing.drafts.failedToClearAll,
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.writing.drafts.title),
        actions: [
          if (drafts.value.isNotEmpty)
            IconButton(
              onPressed: clearAllDrafts,
              icon: const Icon(Symbols.delete_sweep),
              tooltip: context.t.writing.drafts.clearAll,
            ),
          IconButton(
            onPressed: loadDrafts,
            icon: const Icon(Symbols.refresh),
            tooltip: context.t.common.retry,
          ),
        ],
      ),
      body:
          isLoading.value
              ? const Center(
                child: CircularProgressIndicator(),
              )
              : drafts.value.isEmpty
              ? _EmptyDraftsState()
              : RefreshIndicator(
                onRefresh: loadDrafts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drafts.value.length,
                  itemBuilder: (final context, final index) {
                    final draft = drafts.value[index];
                    return _DraftCard(
                      draft: draft,
                      onContinue: () async {
                        await WritingDetailRoute(
                          promptId: draft.promptId,
                        ).push(context);
                      },
                      onDelete: () async => deleteDraft(draft),
                    );
                  },
                ),
              ),
    );
  }
}

class _EmptyDraftsState extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.draft,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              context.t.writing.drafts.noDrafts,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.writing.drafts.noDraftsMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onContinue,
    required this.onDelete,
  });

  final DraftInfo draft;
  final void Function() onContinue;
  final void Function() onDelete;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final prompt = context.t.writing.drafts.prompt;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.auto_awesome,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.t.writing.drafts.autoSaved,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            draft.timeAgo(context),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        draft.preview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Symbols.text_fields,
                            label:
                                '${draft.wordCount} ${context.t.writing.words}',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Symbols.quiz,
                            label: '$prompt #${draft.promptId}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Symbols.edit),
                    label: Text(context.t.writing.drafts.continueWriting),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Symbols.delete),
                  tooltip: context.t.writing.drafts.delete,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DraftInfo>('draft', draft))
      ..add(ObjectFlagProperty<void Function()>.has('onContinue', onContinue))
      ..add(ObjectFlagProperty<void Function()>.has('onDelete', onDelete));
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label));
  }
}
