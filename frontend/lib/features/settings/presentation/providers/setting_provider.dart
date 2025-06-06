import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data_sources/setting_local_data_source.dart';
import '../../data/models/setting_model.dart';
import '../../domain/entities/setting.dart';

part 'setting_provider.g.dart';

@Riverpod(keepAlive: true)
class SettingNotifier extends _$SettingNotifier {
  late final SettingLocalDataSource _localDataSource;

  @override
  Future<Setting> build() async {
    _localDataSource = ref.read(settingLocalDataSourceProvider);
    final model = await _localDataSource.loadSetting();
    const defaultSetting = Setting(
      themeMode: AppThemeMode.system,
      language: AppLanguage.en,
      notificationEnabled: false,
    );
    return model?.toEntity() ?? defaultSetting;
  }

  Future<void> updateSetting(final Setting setting) async {
    state = AsyncValue.data(setting);
    await _localDataSource.saveSetting(
      SettingModel(
        themeMode: setting.themeMode.name,
        language: setting.language.name,
        notificationEnabled: setting.notificationEnabled,
      ),
    );
  }
}
