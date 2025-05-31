import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/word_provider.dart';

class LearnPage extends HookConsumerWidget {
  const LearnPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final wordState = ref.watch(wordControllerProvider);
    useEffect(() {
      Future.microtask(() async {
        await ref.read(wordControllerProvider.notifier).loadWords(limit: 10);
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Words'),
      ),
      body: switch (wordState) {
        WordInitial() => const Center(
          child: CircularProgressIndicator(),
        ),
        WordLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        WordLoaded() => const SizedBox.shrink(),
        WordError() => const SizedBox.shrink(),
      },
    );
  }
}
