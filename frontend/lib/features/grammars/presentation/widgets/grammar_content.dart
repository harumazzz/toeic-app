import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
        // Render trực tiếp nội dung (không Card)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      // Nếu có subTitle hoặc có content đặc biệt, render Card đồng bộ với list
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề nhỏ hơn, đậm
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Html(
            data: element.content,
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
        ),
      if (element.formulas != null && element.formulas!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                element.formulas!
                    .map(
                      (final formula) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Html(
                          data: formula,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontStyle: FontStyle.italic,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: FontSize(15),
                            ),
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      if (element.examples != null && element.examples!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...element.examples!.map(
                (final example) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Html(
                    data: example.example ?? '',
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: FontSize(15),
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
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
