import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../settings/presentation/providers/setting_init_provider.dart';

class ErrorSettings extends StatelessWidget {
  const ErrorSettings({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(final BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.settings.error_occurred),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Symbols.refresh),
              label: Text(context.t.settings.retry),
              onPressed: () async => ref.invalidate(settingInitProvider),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WidgetRef>('ref', ref));
  }
}
