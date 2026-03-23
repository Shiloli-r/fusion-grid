import 'package:get/get.dart';

import '../../data/models/app_settings.dart';
import '../../data/services/storage_service.dart';

class SettingsController extends GetxController {
  final StorageService storage;
  SettingsController({required this.storage});

  final RxBool soundEnabled = AppSettings.defaults.soundEnabled.obs;
  final RxBool vibrationEnabled = AppSettings.defaults.vibrationEnabled.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final settings = await storage.getSettings();
    soundEnabled.value = settings.soundEnabled;
    vibrationEnabled.value = settings.vibrationEnabled;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled.value = enabled;
    await storage.setSettings(AppSettings(
      soundEnabled: soundEnabled.value,
      vibrationEnabled: vibrationEnabled.value,
    ));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    vibrationEnabled.value = enabled;
    await storage.setSettings(AppSettings(
      soundEnabled: soundEnabled.value,
      vibrationEnabled: vibrationEnabled.value,
    ));
  }
}

