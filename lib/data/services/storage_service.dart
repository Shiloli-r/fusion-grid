import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class StorageService {
  static const String _bestScoreKey = 'fusion_grid_best_score';
  static const String _soundEnabledKey = 'fusion_grid_sound_enabled';
  static const String _vibrationEnabledKey = 'fusion_grid_vibration_enabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<int> getBestScore() async {
    final p = await _prefs;
    return p.getInt(_bestScoreKey) ?? 0;
  }

  Future<void> setBestScore(int score) async {
    final p = await _prefs;
    await p.setInt(_bestScoreKey, score);
  }

  Future<AppSettings> getSettings() async {
    final p = await _prefs;
    return AppSettings(
      soundEnabled: p.getBool(_soundEnabledKey) ?? AppSettings.defaults.soundEnabled,
      vibrationEnabled:
          p.getBool(_vibrationEnabledKey) ?? AppSettings.defaults.vibrationEnabled,
    );
  }

  Future<void> setSettings(AppSettings settings) async {
    final p = await _prefs;
    await p.setBool(_soundEnabledKey, settings.soundEnabled);
    await p.setBool(_vibrationEnabledKey, settings.vibrationEnabled);
  }
}

