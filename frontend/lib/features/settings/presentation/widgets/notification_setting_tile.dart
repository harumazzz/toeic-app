import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../i18n/strings.g.dart';

class NotificationSettingTile extends ConsumerWidget {
  const NotificationSettingTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      SwitchListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(context.t.settings.notification),
        value: value,
        onChanged: onChanged,
        subtitle: Text(
          value
              ? context.t.settings.notification_enabled
              : context.t.settings.notification_disabled,
        ),
      );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged),
      );
  }
}
