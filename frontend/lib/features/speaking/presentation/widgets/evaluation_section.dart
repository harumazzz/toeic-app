import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EvaluationSection extends StatelessWidget {
  const EvaluationSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final IconData icon;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        content,
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('content', content))
      ..add(DiagnosticsProperty<IconData>('icon', icon));
  }
}
