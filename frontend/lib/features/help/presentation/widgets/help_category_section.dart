import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HelpCategorySection extends StatelessWidget {
  const HelpCategorySection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;

  final IconData icon;

  final List<HelpItem> items;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      ...items.map((final item) => HelpExpansionTile(item: item)),
      const Divider(thickness: 1),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(IterableProperty<HelpItem>('items', items));
  }
}

class HelpItem {
  const HelpItem({
    required this.title,
    required this.content,
  });
  final String title;
  final String content;
}

class HelpExpansionTile extends StatelessWidget {
  const HelpExpansionTile({
    super.key,
    required this.item,
  });
  final HelpItem item;

  @override
  Widget build(final BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    child: ExpansionTile(
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedAlignment: Alignment.topLeft,
      children: [
        Text(
          item.content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HelpItem>('item', item));
  }
}
