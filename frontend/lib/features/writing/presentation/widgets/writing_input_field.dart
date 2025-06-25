import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WritingInputField extends StatelessWidget {
  const WritingInputField({
    required this.controller,
    required this.hintText,
    this.maxLines = 10,
    this.maxLength,
    this.onChanged,
    this.errorText,
    super.key,
  });
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
        ),
      )
      ..add(StringProperty('hintText', hintText))
      ..add(IntProperty('maxLines', maxLines))
      ..add(IntProperty('maxLength', maxLength))
      ..add(
        ObjectFlagProperty<ValueChanged<String>?>.has('onChanged', onChanged),
      )
      ..add(StringProperty('errorText', errorText));
  }
}
