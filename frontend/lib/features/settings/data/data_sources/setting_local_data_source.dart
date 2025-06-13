import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setting_model.dart';

part 'setting_local_data_source.g.dart';

@riverpod
SettingLocalDataSource settingLocalDataSource(
  final Ref ref,
) => const SettingLocalDataSource();

class SettingLocalDataSource {
  const SettingLocalDataSource();

  static const _key = 'app_settings';

  Future<void> saveSetting(
    final SettingModel model,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = _encodeSetting(model);
    await prefs.setString(_key, jsonStr);
  }

  Future<SettingModel?> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) {
      return null;
    }
    final result = _decodeSetting(str);
    return result;
  }
}

String _encodeSetting(
  final SettingModel model,
) => jsonEncode(model.toJson());

SettingModel _decodeSetting(
  final String str,
) => SettingModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
