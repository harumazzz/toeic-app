import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../i18n/strings.g.dart';
import '../../providers/word_detail_provider.dart';

class WordDetailError extends StatelessWidget {
  const WordDetailError({
    required this.message,
    required this.wordId,
    super.key,
  });

  final String message;
  final int wordId;

  @override
  Widget build(final BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            context.t.wordDetail.failedToLoad,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Consumer(
            builder:
                (final context, final ref, final child) => FilledButton.icon(
                  onPressed: () async {
                    final wordProvider = ref.read(
                      wordDetailControllerProvider.notifier,
                    );
                    await wordProvider.loadWord(wordId);
                  },
                  icon: const Icon(Symbols.refresh),
                  label: Text(context.t.common.retry),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
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
      ..add(IntProperty('wordId', wordId));
  }
}
