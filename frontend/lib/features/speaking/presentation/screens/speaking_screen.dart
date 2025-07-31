import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/speaking_provider.dart';
import '../widgets/speaking_session_card.dart';

class SpeakingScreen extends HookConsumerWidget {
  const SpeakingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(speakingSessionsProvider);

    useEffect(() {
      Future.microtask(
        () => ref.read(speakingSessionsProvider.notifier).loadSessions(),
      );
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.speaking.title),
        actions: [
          IconButton(
            onPressed: () => const ToeicPracticeRoute().push(context),
            icon: const Icon(Symbols.school),
            tooltip: 'TOEIC Practice',
          ),
        ],
      ),
      body: switch (state) {
        SpeakingStateInitial() => const Center(
          child: CircularProgressIndicator(),
        ),
        SpeakingStateLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        SpeakingStateLoaded(:final sessions) =>
          sessions.isEmpty
              ? Center(
                  child: Text(context.t.speaking.noSessions),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (final context, final index) {
                    final session = sessions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SpeakingSessionCard(session: session),
                    );
                  },
                ),
        SpeakingStateError(:final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async =>
                    ref.read(speakingSessionsProvider.notifier).loadSessions(),
                child: Text(context.t.common.retry),
              ),
            ],
          ),
        ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () async =>
            const SpeakingDetailRoute(sessionId: -1).push(context),
        child: const Icon(Symbols.add),
      ),
    );
  }
}
