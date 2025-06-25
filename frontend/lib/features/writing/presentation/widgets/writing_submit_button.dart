import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/strings.g.dart';

class WritingSubmitButton extends StatelessWidget {
  const WritingSubmitButton({
    this.onPressed,
    this.isLoading = false,
    this.text,
    super.key,
  });
  final void Function()? onPressed;
  final bool isLoading;
  final String? text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.12,
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
                : Text(
                  text ?? context.t.writing.submitWriting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<void Function()?>.has('onPressed', onPressed),
      )
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('text', text));
  }
}
