import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EvaluationList extends StatelessWidget {
  const EvaluationList({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ...items.map(
        (final item) => Padding(
          padding: const EdgeInsets.only(left: 22, bottom: 2),
          child: Text(
            '• $item',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IterableProperty<String>('items', items))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color));
  }
}
