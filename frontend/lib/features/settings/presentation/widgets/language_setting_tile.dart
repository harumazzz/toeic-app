import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/setting.dart';

class LanguageSettingTile extends ConsumerWidget {
  const LanguageSettingTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final void Function(AppLanguage language) onChanged;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = context.t;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(l10n.settings.language),
      subtitle: Text(_langLabel(l10n, value)),
      onTap: () async {
        final selected = await showDialog<AppLanguage>(
          context: context,
          builder:
              (final context) => AlertDialog(
                title: Text(l10n.settings.language),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final lang in AppLanguage.values)
                      RadioListTile<AppLanguage>(
                        value: lang,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        groupValue: value,
                        title: Text(_langLabel(l10n, lang)),
                        onChanged:
                            (final lang) => Navigator.of(context).pop(lang),
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
      ..add(
        ObjectFlagProperty<void Function(AppLanguage value)>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(EnumProperty<AppLanguage>('value', value));
  }
}

String _langLabel(
  final Translations l10n,
  final AppLanguage lang,
) {
  switch (lang) {
    case AppLanguage.en:
      return l10n.settings.lang_en;
    case AppLanguage.vi:
      return l10n.settings.lang_vi;
  }
}
