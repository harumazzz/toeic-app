import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../../core/services/toast_service.dart';
import '../../../../../i18n/strings.g.dart';
import '../../../domain/entities/word.dart';
import '../../providers/word_detail_provider.dart';

class CollapsibleActionButton extends HookConsumerWidget {
  const CollapsibleActionButton({
    required this.word,
    super.key,
  });

  final Word word;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bookmarkWord = ref.watch(bookmarkWordProvider);
    final isFetching = useState(false);
    ref.listen<BookMarkWordState>(
      bookmarkWordProvider,
      (final previous, final next) {
        if (next is BookMarkWordError) {
          isFetching.value = false;
          ToastService.error(
            context: context,
            message: next.message,
          );
        }
      },
    );
    useEffect(() {
      ref.read(bookmarkWordProvider.notifier).loadBookmark(word);
      return null;
    }, [word.id]);

    return switch (bookmarkWord) {
      BookMarkWordInitial _ => Shimmer(
        color: Theme.of(context).colorScheme.primary.withValues(
          alpha: 0.3,
        ),
        child: const FloatingActionButton(
          heroTag: 'bookmark-shimmer',
          onPressed: null,
          child: Icon(Symbols.bookmark),
        ),
      ),
      BookMarkWordNone _ => FloatingActionButton(
        heroTag: 'add-bookmark',
        tooltip: context.t.wordDetail.addLearn,
        onPressed: () async {
          isFetching.value = true;
          await ref.read(bookmarkWordProvider.notifier).addBookmark(word);
          isFetching.value = false;
          if (context.mounted) {
            ToastService.success(
              context: context,
              message: context.t.wordDetail.addedToLearn,
            );
          }
        },
        child: const Icon(Symbols.bookmark_add),
      ),
      BookMarkWordBookmarked _ => FloatingActionButton(
        heroTag: 'remove-bookmark',
        tooltip: context.t.wordDetail.removeLearn,
        onPressed: () async {
          isFetching.value = true;
          await ref.read(bookmarkWordProvider.notifier).removeBookmark(word);
          isFetching.value = false;
          if (context.mounted) {
            ToastService.info(
              context: context,
              message: context.t.wordDetail.removedFromLearn,
            );
          }
        },
        child: const Icon(Symbols.bookmark_remove),
      ),
      BookMarkWordError _ => const SizedBox.shrink(),
    };
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Word>('word', word));
  }
}
