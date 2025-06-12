import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/grammar.dart' as grammar;

class GrammarContent extends StatelessWidget {
  const GrammarContent({
    super.key,
    required this.contents,
  });

  final List<grammar.Content> contents;

  @override
  Widget build(final BuildContext context) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: contents.length,
    itemBuilder: (final context, final index) {
      final content = contents[index];
      final hasSubTitle =
          content.subTitle != null && content.subTitle!.trim().isNotEmpty;
      final hasContent = content.content != null && content.content!.isNotEmpty;
      if (!hasSubTitle &&
          hasContent &&
          content.content!.every(
            (final e) => e.content != null && e.content!.trim().isNotEmpty,
          )) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...content.content!.map(
                (final element) => _GrammarContentElement(element: element),
              ),
            ],
          ),
        );
      }
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSubTitle)
                Text(
                  content.subTitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasSubTitle) const SizedBox(height: 8),
              if (hasContent)
                ...content.content!.map(
                  (final element) => _GrammarContentElement(element: element),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<grammar.Content>('contents', contents));
  }
}

class _GrammarContentElement extends StatelessWidget {
  const _GrammarContentElement({required this.element});
  final grammar.ContentElement element;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (element.content != null && element.content!.trim().isNotEmpty)
        _ContentCard(content: element.content!),
      if (element.formulas != null && element.formulas!.isNotEmpty)
        _FormulaCard(formulas: element.formulas!),
      if (element.examples != null && element.examples!.isNotEmpty)
        _ExampleCard(examples: element.examples!),
      const SizedBox(height: 16),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<grammar.ContentElement>('element', element),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.content});
  final String content;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Html(
      data: content,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: FontSize(15),
        ),
        'span': Style(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      },
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('content', content));
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.formulas});
  final List<String> formulas;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.rule,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Formula',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...formulas.map(
          (final formula) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Html(
              data: formula,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: FontSize(15),
                ),
              },
            ),
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('formulas', formulas));
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.examples});
  final List<grammar.Example> examples;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.lightbulb_outline,
              size: 20,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Examples',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...examples.map(
          (final example) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Html(
              data: example.example ?? '',
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: FontSize(15),
                ),
              },
            ),
          ),
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<grammar.Example>('examples', examples));
  }
}
