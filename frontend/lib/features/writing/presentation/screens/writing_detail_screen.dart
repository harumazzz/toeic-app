import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_writing.dart';
import '../../domain/entities/writing_prompt.dart';
import '../providers/user_writing_provider.dart';
import '../providers/writing_prompt_provider.dart';
import '../utils/writing_draft_manager.dart';
import '../widgets/writing_input_field.dart';
import '../widgets/writing_submit_button.dart';

class WritingDetailScreen extends HookConsumerWidget {
  const WritingDetailScreen({
    required this.promptId,
    super.key,
  });
  final int promptId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final t = Translations.of(context);
    final textController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final wordCount = useState(0);
    const int minWords = 50;
    const int maxWords = 500;

    final promptState = ref.watch(singleWritingPromptControllerProvider);

    useEffect(() {
      Future.microtask(() async {
        await ref
            .read(singleWritingPromptControllerProvider.notifier)
            .loadWritingPrompt(promptId);
      });
      return null;
    }, [promptId]);

    if (promptState is SingleWritingPromptLoading) {
      return _LoadingScaffold(title: t.writing.writeYourResponse);
    }

    if (promptState is SingleWritingPromptError) {
      return _ErrorScaffold(
        title: t.writing.writeYourResponse,
        error: promptState.message,
        onRetry: () async {
          await ref
              .read(singleWritingPromptControllerProvider.notifier)
              .loadWritingPrompt(promptId);
        },
      );
    }

    if (promptState is! SingleWritingPromptLoaded) {
      return _LoadingScaffold(title: t.writing.writeYourResponse);
    }

    final prompt = promptState.prompt;

    return _WritingDetailContent(
      prompt: prompt,
      textController: textController,
      formKey: formKey,
      wordCount: wordCount,
      minWords: minWords,
      maxWords: maxWords,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('promptId', promptId));
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: CircularProgressIndicator()),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;

  final String error;

  final void Function() onRetry;

  @override
  Widget build(final BuildContext context) {
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '${context.t.common.error}: $error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(t.common.retry),
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
      ..add(StringProperty('title', title))
      ..add(StringProperty('error', error))
      ..add(ObjectFlagProperty<void Function()>.has('onRetry', onRetry));
  }
}

class _WritingDetailContent extends HookConsumerWidget {
  const _WritingDetailContent({
    required this.prompt,
    required this.textController,
    required this.formKey,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
  });

  final WritingPrompt prompt;
  final TextEditingController textController;
  final GlobalKey<FormState> formKey;
  final ValueNotifier<int> wordCount;
  final int minWords;
  final int maxWords;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    Future<void> updateWordCount() async {
      final text = textController.text.trim();
      final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
      wordCount.value = words;

      if (text.isNotEmpty) {
        WritingDraftManager.saveDraft(prompt.id, text);
      }
    }

    Future<void> submitWriting() async {
      if (!formKey.currentState!.validate()) {
        return;
      }

      if (wordCount.value < minWords) {
        ToastService.error(
          context: context,
          message: t.writing.minWordsRequired.replaceAll(
            '{}',
            minWords.toString(),
          ),
        );
        return;
      }

      final authState = ref.read(authControllerProvider);
      if (authState is! AuthAuthenticated) {
        ToastService.error(
          context: context,
          message: t.writing.mustBeLoggedIn,
        );
        return;
      }

      final request = UserWritingRequest(
        userId: authState.user.id,
        promptId: prompt.id,
        submissionText: textController.text.trim(),
      );
      await ref
          .read(userWritingSubmissionControllerProvider.notifier)
          .submitWriting(request);
    }

    useEffect(() {
      Future<void> loadDraft() async {
        try {
          final draft = await WritingDraftManager.loadDraft(prompt.id);
          if (draft != null && draft.isNotEmpty) {
            textController.text = draft;
            await updateWordCount();
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

      loadDraft();
      return null;
    }, []);

    useEffect(() {
      Future<void> listener() async => updateWordCount();
      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    useEffect(() => WritingDraftManager.dispose, []);

    final submissionState = ref.watch(userWritingSubmissionControllerProvider);

    ref.listen<UserWritingSubmissionState>(
      userWritingSubmissionControllerProvider,
      (final previous, final next) async {
        switch (next) {
          case UserWritingSubmissionSubmitted():
            await WritingDraftManager.clearDraft(prompt.id);
            if (context.mounted) {
              ToastService.success(
                context: context,
                message: t.writing.writingSubmittedSuccessfully,
              );
              Navigator.pop(context);
            }
            break;
          case UserWritingSubmissionError(:final message):
            if (context.mounted) {
              ToastService.error(
                context: context,
                message: t.writing.failedToSubmit.replaceAll('{}', message),
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
        title: Text(
          t.writing.writeYourResponse,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            Expanded(
              child: _WritingContent(
                prompt: prompt,
                textController: textController,
                wordCount: wordCount,
                minWords: minWords,
                maxWords: maxWords,
                onChanged: updateWordCount,
              ),
            ),
            _WritingActions(
              prompt: prompt,
              textController: textController,
              isSubmitting: isSubmitting,
              onSubmit: submitWriting,
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
      ..add(DiagnosticsProperty<WritingPrompt>('prompt', prompt))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'textController',
          textController,
        ),
      )
      ..add(
        DiagnosticsProperty<GlobalKey<FormState>>('formKey', formKey),
      )
      ..add(
        DiagnosticsProperty<ValueNotifier<int>>('wordCount', wordCount),
      )
      ..add(IntProperty('minWords', minWords))
      ..add(IntProperty('maxWords', maxWords));
  }
}

class _WritingContent extends StatelessWidget {
  const _WritingContent({
    required this.prompt,
    required this.textController,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
    required this.onChanged,
  });

  final WritingPrompt prompt;
  final TextEditingController textController;
  final ValueNotifier<int> wordCount;
  final int minWords;
  final int maxWords;
  final void Function() onChanged;

  @override
  Widget build(final BuildContext context) {
    final t = Translations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PromptCard(prompt: prompt),
          const SizedBox(height: 24),
          const WritingInstructions(),
          const SizedBox(height: 24),
          WordCountIndicator(
            currentCount: wordCount.value,
            minWords: minWords,
            maxWords: maxWords,
          ),
          const SizedBox(height: 16),
          WritingInputField(
            controller: textController,
            hintText: t.writing.startWritingHere,
            maxLines: 15,
            maxLength: maxWords * 10,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<WritingPrompt>('prompt', prompt))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'textController',
          textController,
        ),
      )
      ..add(
        DiagnosticsProperty<ValueNotifier<int>>('wordCount', wordCount),
      )
      ..add(IntProperty('minWords', minWords))
      ..add(IntProperty('maxWords', maxWords))
      ..add(
        ObjectFlagProperty<void Function()>.has('onChanged', onChanged),
      );
  }
}

class _WritingActions extends StatelessWidget {
  const _WritingActions({
    required this.prompt,
    required this.textController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final WritingPrompt prompt;
  final TextEditingController textController;
  final bool isSubmitting;
  final void Function() onSubmit;

  @override
  Widget build(final BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed:
                textController.text.trim().isNotEmpty && !isSubmitting
                    ? () async => _saveDraft(
                      context,
                      prompt.id,
                      textController.text.trim(),
                    )
                    : null,
            icon: const Icon(Symbols.save),
            label: Text(t.common.save),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: WritingSubmitButton(
              onPressed:
                  textController.text.trim().isNotEmpty && !isSubmitting
                      ? onSubmit
                      : null,
              isLoading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft(
    final BuildContext context,
    final int promptId,
    final String text,
  ) async {
    final t = Translations.of(context);

    try {
      WritingDraftManager.saveDraft(promptId, text);
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        ToastService.success(
          context: context,
          message: t.writing.drafts.draftCleared.replaceAll('cleared', 'saved'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.error(
          context: context,
          message: '${context.t.writing.drafts.failedToSave}: $e',
        );
      }
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<WritingPrompt>('prompt', prompt))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'textController',
          textController,
        ),
      )
      ..add(DiagnosticsProperty<bool>('isSubmitting', isSubmitting))
      ..add(ObjectFlagProperty<void Function()>.has('onSubmit', onSubmit));
  }
}

class PromptCard extends StatelessWidget {
  const PromptCard({required this.prompt, super.key});
  final WritingPrompt prompt;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.quiz,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.writingPrompt,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            prompt.promptText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (prompt.topic != null || prompt.difficultyLevel != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (prompt.topic != null)
                  _CustomChip(
                    label: prompt.topic!,
                    icon: Symbols.topic,
                  ),
                if (prompt.difficultyLevel != null)
                  _CustomChip(
                    label: prompt.difficultyLevel!,
                    icon: Symbols.signal_cellular_alt,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WritingPrompt>('prompt', prompt));
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
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
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<IconData>('icon', icon));
  }
}

class WritingInstructions extends StatelessWidget {
  const WritingInstructions({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.t.writing.writingTips,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '• ${context.t.writing.tips.writeClearly}',
            '• ${context.t.writing.tips.useProperGrammar}',
            '• ${context.t.writing.tips.stayOnTopic}',
            '• ${context.t.writing.tips.useVariedVocabulary}',
          ].map(
            (final tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                tip,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WordCountIndicator extends StatelessWidget {
  const WordCountIndicator({
    required this.currentCount,
    required this.minWords,
    required this.maxWords,
    super.key,
  });
  final int currentCount;
  final int minWords;
  final int maxWords;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentCount / maxWords).clamp(0.0, 1.0);

    Color getCountColor() {
      if (currentCount < minWords) {
        return Colors.red;
      }
      if (currentCount > maxWords) {
        return Colors.red;
      }
      return Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t.writing.wordCount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$currentCount / $maxWords words',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: getCountColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(getCountColor()),
        ),
        const SizedBox(height: 4),
        Text(
          currentCount < minWords
              ? context.t.writing.minimumWordsRequired.replaceAll(
                '{}',
                minWords.toString(),
              )
              : currentCount > maxWords
              ? context.t.writing.exceededMaximumWordLimit
              : context.t.writing.goodLength,
          style: theme.textTheme.bodySmall?.copyWith(
            color: getCountColor(),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('currentCount', currentCount))
      ..add(IntProperty('minWords', minWords))
      ..add(IntProperty('maxWords', maxWords));
  }
}
