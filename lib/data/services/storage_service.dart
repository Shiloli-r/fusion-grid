import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/best_run.dart';

class StorageService {
  static const String _bestScoreKeyLegacy = 'fusion_grid_best_score';
  static const String _soundEnabledKey = 'fusion_grid_sound_enabled';
  static const String _vibrationEnabledKey = 'fusion_grid_vibration_enabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _bestScoreKeyForMode(String modeId) => 'fusion_grid_best_score_$modeId';
  String _bestStepsKeyForMode(String modeId) => 'fusion_grid_best_steps_$modeId';
  String _bestDurationKeyForMode(String modeId) =>
      'fusion_grid_best_duration_seconds_$modeId';

  /// Best run for a specific mode (score + steps + duration).
  Future<BestRun> getBestRun({required String modeId}) async {
    final p = await _prefs;
    final score = p.getInt(_bestScoreKeyForMode(modeId)) ?? 0;
    final steps = p.getInt(_bestStepsKeyForMode(modeId)) ?? 0;
    final duration = p.getInt(_bestDurationKeyForMode(modeId)) ?? 0;
    return BestRun(score: score, steps: steps, durationSeconds: duration);
  }

  Future<void> setBestRun({required String modeId, required BestRun run}) async {
    final p = await _prefs;
    await p.setInt(_bestScoreKeyForMode(modeId), run.score);
    await p.setInt(_bestStepsKeyForMode(modeId), run.steps);
    await p.setInt(_bestDurationKeyForMode(modeId), run.durationSeconds);
  }

  /// Legacy best score (pre per-mode best runs). Used once to migrate.
  Future<int> getLegacyBestScore() async {
    final p = await _prefs;
    return p.getInt(_bestScoreKeyLegacy) ?? 0;
  }

  Future<void> clearLegacyBestScore() async {
    final p = await _prefs;
    await p.remove(_bestScoreKeyLegacy);
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

