import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_writing.dart';
import '../providers/user_writing_provider.dart';
import '../utils/writing_draft_manager.dart';

class PracticeWritingScreen extends HookConsumerWidget {
  const PracticeWritingScreen({
    super.key,
    this.prompt,
    this.promptId,
  });

  final String? prompt;
  final int? promptId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textController = useTextEditingController();
    final wordCount = useState(0);
    final charCount = useState(0);
    final isLoading = useState(false);

    Future<void> updateCounts() async {
      final text = textController.text;
      wordCount.value = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
      charCount.value = text.length;
    }

    useEffect(() {
      Future<void> loadDraft() async {
        if (promptId != null) {
          try {
            final draft = await WritingDraftManager.loadDraft(promptId!);
            if (draft != null) {
              textController.text = draft;
              await updateCounts();
            }
          } catch (e) {
            if (context.mounted) {
              ToastService.error(
                context: context,
                message: context.t.writing.drafts.failedToLoad,
              );
            }
          }
        }
      }

      loadDraft();
      return null;
    }, [promptId]);

    Future<void> saveDraftManually() async {
      if (promptId == null) {
        ToastService.error(
          context: context,
          message: context.t.writing.drafts.cannotSaveDraftWithoutPromptId,
        );
        return;
      }

      if (textController.text.trim().isEmpty) {
        ToastService.error(
          context: context,
          message: context.t.writing.drafts.cannotSaveEmptyDraft,
        );
        return;
      }

      try {
        isLoading.value = true;
        WritingDraftManager.saveDraft(promptId!, textController.text.trim());
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          ToastService.success(
            context: context,
            message: context.t.writing.drafts.draftSavedSuccessfully,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: context.t.writing.drafts.failedToSave,
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> submitWriting() async {
      if (textController.text.trim().isEmpty) {
        ToastService.error(
          context: context,
          message:
              context.t.writing.drafts.pleaseWriteSomethingBeforeSubmitting,
        );
        return;
      }

      // Check authentication
      final authState = ref.read(authControllerProvider);
      if (authState is! AuthAuthenticated) {
        ToastService.error(
          context: context,
          message: context.t.writing.mustBeLoggedIn,
        );
        return;
      }

      try {
        isLoading.value = true;

        // Save draft before submitting
        if (promptId != null) {
          WritingDraftManager.saveDraft(
            promptId!,
            textController.text.trim(),
          );
        }

        // Create the request for backend submission
        final request = UserWritingRequest(
          userId: authState.user.id,
          promptId: promptId,
          submissionText: textController.text.trim(),
        );

        // Submit to backend
        await ref
            .read(userWritingSubmissionControllerProvider.notifier)
            .submitWriting(request);
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: 'Failed to submit: $e',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Listen to submission state changes
    final submissionState = ref.watch(userWritingSubmissionControllerProvider);

    ref.listen<UserWritingSubmissionState>(
      userWritingSubmissionControllerProvider,
      (final previous, final next) async {
        switch (next) {
          case UserWritingSubmissionSubmitted():
            // Clear draft after successful submission
            if (promptId != null) {
              await WritingDraftManager.clearDraft(promptId!);
            }
            if (context.mounted) {
              ToastService.success(
                context: context,
                message: context.t.writing.writingSubmittedSuccessfully,
              );
              // Navigate to success screen
              WritingSubmissionSuccessRoute(
                wordCount: wordCount.value,
                content: textController.text.trim(),
                prompt: prompt,
              ).pushReplacement(context);
            }
            break;
          case UserWritingSubmissionError(:final message):
            if (context.mounted) {
              ToastService.error(
                context: context,
                message: context.t.writing.failedToSubmit.replaceAll(
                  '{}',
                  message,
                ),
              );
            }
            break;
          default:
            break;
        }
      },
    );

    final isSubmitting = submissionState is UserWritingSubmissionSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.writing.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prompt != null && prompt!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prompt!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Expanded(
              child: TextField(
                controller: textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start writing your practice essay here...',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => updateCounts(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${context.t.writing.drafts.words}: ${wordCount.value}'),
                Text(
                  '${context.t.writing.drafts.characters}: ${charCount.value}',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              onPressed: isSubmitting ? null : saveDraftManually,
              icon:
                  isLoading.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Symbols.save),
              tooltip: context.t.writing.drafts.saveDraft,
            ),
            IconButton(
              onPressed: () async {
                // TODO(dev): Save as file functionality
                ToastService.info(
                  context: context,
                  message: context.t.writing.drafts.saveSuccessfully,
                );
              },
              icon: const Icon(Symbols.file_download),
              tooltip: context.t.writing.drafts.saveAsFile,
            ),
            const Spacer(),
            FloatingActionButton(
              tooltip: context.t.writing.drafts.submit,
              onPressed: isSubmitting ? null : submitWriting,
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Symbols.check),
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
      ..add(StringProperty('prompt', prompt))
      ..add(IntProperty('promptId', promptId));
  }
}
