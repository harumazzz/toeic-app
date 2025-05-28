import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(final BuildContext context) => Center(
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
