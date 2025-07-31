import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PracticeButton extends StatelessWidget {
  const PracticeButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed),
      );
  }
}
