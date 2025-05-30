import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthActionButton extends ConsumerWidget {
  const AuthActionButton({
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    super.key,
  });

  final String primaryButtonText;
  final String secondaryButtonText;
  final void Function() onPrimaryPressed;
  final void Function() onSecondaryPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [
      Consumer(
        builder: (final context, final ref, final child) {
          final authState = ref.watch(authControllerProvider);

          switch (authState) {
            case AuthInitial():
            case AuthUnauthenticated():
            case AuthError():
              return FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                ),
                onPressed: onPrimaryPressed,
                child: Text(primaryButtonText),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onSecondaryPressed,
        child: Text(secondaryButtonText),
      ),
    ],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('primaryButtonText', primaryButtonText))
      ..add(StringProperty('secondaryButtonText', secondaryButtonText))
      ..add(
        ObjectFlagProperty<void Function()>.has(
          'onPrimaryPressed',
          onPrimaryPressed,
        ),
      )
      ..add(
        ObjectFlagProperty<void Function()>.has(
          'onSecondaryPressed',
          onSecondaryPressed,
        ),
      );
  }
}
