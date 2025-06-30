import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../i18n/strings.g.dart';

class WordNotificationSettingTile extends ConsumerWidget {
  const WordNotificationSettingTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isMainNotificationEnabled,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isMainNotificationEnabled;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      SwitchListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(context.t.settings.wordNotifications),
        subtitle: Text(
          value
              ? context.t.settings.wordNotifications_enabled
              : context.t.settings.wordNotifications_disabled,
        ),
        value: value && isMainNotificationEnabled,
        onChanged: isMainNotificationEnabled ? onChanged : null,
      );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(
        DiagnosticsProperty<bool>(
          'isMainNotificationEnabled',
          isMainNotificationEnabled,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged),
      );
  }
}

class WordNotificationFrequencyTile extends ConsumerWidget {
  const WordNotificationFrequencyTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isEnabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool isEnabled;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = context.t;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(l10n.settings.notificationFrequency),
      subtitle: Text(_frequencyLabel(l10n, value)),
      onTap: isEnabled
          ? () async {
              final frequencies = [
                'daily',
                'twiceDaily',
                'threeTimesDaily',
                'hourly',
              ];
              final selected = await showDialog<String>(
                context: context,
                builder: (final context) => AlertDialog(
                  title: Text(l10n.settings.notificationFrequency),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final frequency in frequencies)
                        RadioListTile<String>(
                          value: frequency,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          groupValue: value,
                          title: Text(_frequencyLabel(l10n, frequency)),
                          onChanged: (final frequency) async =>
                              Navigator.of(context).pop(frequency),
                        ),
                    ],
                  ),
                ),
              );
              if (selected != null && selected != value) {
                onChanged(selected);
              }
            }
          : null,
      enabled: isEnabled,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('value', value))
      ..add(DiagnosticsProperty<bool>('isEnabled', isEnabled))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onChanged',
          onChanged,
        ),
      );
  }
}

class WordNotificationTimeTile extends ConsumerWidget {
  const WordNotificationTimeTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isEnabled,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool isEnabled;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = context.t;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(l10n.settings.notificationTime),
      subtitle: Text('${value.toString().padLeft(2, '0')}:00'),
      onTap: isEnabled
          ? () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: value, minute: 0),
                builder: (final context, final child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    alwaysUse24HourFormat: true,
                  ),
                  child: child!,
                ),
              );

              if (selectedTime != null && selectedTime.hour != value) {
                onChanged(selectedTime.hour);
              }
            }
          : null,
      enabled: isEnabled,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(DiagnosticsProperty<bool>('isEnabled', isEnabled))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged),
      );
  }
}

String _frequencyLabel(final Translations l10n, final String frequency) {
  switch (frequency) {
    case 'daily':
      return l10n.settings.frequency_daily;
    case 'twiceDaily':
      return l10n.settings.frequency_twice_daily;
    case 'threeTimesDaily':
      return l10n.settings.frequency_three_times_daily;
    case 'hourly':
      return l10n.settings.frequency_hourly;
    default:
      return l10n.settings.frequency_daily;
  }
}
