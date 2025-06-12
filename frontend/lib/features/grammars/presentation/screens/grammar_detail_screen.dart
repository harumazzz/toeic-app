import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../domain/entities/grammar.dart';
import '../providers/grammar_provider.dart';
import '../widgets/grammar_content.dart';
import '../widgets/grammar_content_shimmer.dart';
import '../widgets/grammar_list_item.dart';

class GrammarDetailScreen extends HookConsumerWidget {
  const GrammarDetailScreen({
    super.key,
    required this.grammarId,
  });

  final int grammarId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(grammarDetailProvider.notifier).loadGrammar(grammarId);
      });
      return null;
    }, [grammarId]);

    final state = ref.watch(grammarDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.grammar?.title ?? 'Grammar Detail'),
      ),
      body: _GrammarDetailBody(state: state),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('grammarId', grammarId));
  }
}

class _GrammarDetailBody extends StatelessWidget {
  const _GrammarDetailBody({required this.state});
  final GrammarDetailState state;

  @override
  Widget build(final BuildContext context) {
    if (state.isLoading) {
      return const _LoadingView();
    } else if (state.error != null) {
      return _ErrorView(error: state.error!);
    } else if (state.grammar == null) {
      return const _NotFoundView();
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.grammar!.tag != null && state.grammar!.tag!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _TagWrap(tags: state.grammar!.tag!),
            ),
          if (state.grammar!.contents != null)
            GrammarContent(
              contents: state.grammar!.contents!,
            ),
          if (state.relatedGrammars.isNotEmpty)
            _RelatedGrammarsSection(grammars: state.relatedGrammars),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GrammarDetailState>('state', state));
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});
  final List<String> tags;
  @override
  Widget build(final BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 2,
    children: [
      ...tags.map(
        (final tag) => Chip(
          label: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('tags', tags));
  }
}

class _RelatedGrammarsSection extends StatelessWidget {
  const _RelatedGrammarsSection({
    required this.grammars,
  });
  final List<Grammar> grammars;
  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          context.t.grammar.relatedGrammars,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: grammars.length,
        itemBuilder: (final context, final index) {
          final grammar = grammars[index];
          return GrammarListItem(
            grammar: grammar,
            onTap: () async {
              await GrammarDetailRoute(
                grammarId: grammar.id,
              ).push(context);
            },
          );
        },
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Grammar>('grammars', grammars));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;
  @override
  Widget build(final BuildContext context) => Center(child: Text(error));

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('error', error));
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(final BuildContext context) => const SingleChildScrollView(
    child: Column(
      children: [
        GrammarContentShimmer(),
        GrammarContentShimmer(),
      ],
    ),
  );
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();
  @override
  Widget build(final BuildContext context) =>
      const Center(child: Text('Grammar not found'));
}
