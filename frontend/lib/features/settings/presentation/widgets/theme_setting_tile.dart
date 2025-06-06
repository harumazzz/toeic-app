import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/setting.dart';

class ThemeSettingTile extends ConsumerWidget {
  const ThemeSettingTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppThemeMode value;
  final void Function(AppThemeMode mode) onChanged;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = context.t;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(l10n.settings.theme),
      subtitle: Text(_themeLabel(l10n, value)),
      onTap: () async {
        final selected = await showDialog<AppThemeMode>(
          context: context,
          builder:
              (final context) => AlertDialog(
                title: Text(l10n.settings.theme),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in AppThemeMode.values)
                      RadioListTile<AppThemeMode>(
                        value: mode,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        groupValue: value,
                        title: Text(_themeLabel(l10n, mode)),
                        onChanged:
                            (final mode) async => Navigator.of(context).pop(
                              mode,
                            ),
                      ),
                  ],
                ),
              ),
        );
        if (selected != null && selected != value) {
          onChanged(selected);
        }
      },
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<AppThemeMode>('value', value))
      ..add(
        ObjectFlagProperty<void Function(AppThemeMode mode)>.has(
          'onChanged',
          onChanged,
        ),
      );
  }
}

String _themeLabel(final Translations l10n, final AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return l10n.settings.theme_system;
    case AppThemeMode.light:
      return l10n.settings.theme_light;
    case AppThemeMode.dark:
      return l10n.settings.theme_dark;
  }
}
