import 'package:get/get.dart';

import '../core/controllers/settings_controller.dart';
import '../core/services/play_in_app_update_service.dart';
import '../core/services/score_share_service.dart';
import '../data/services/storage_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ScoreShareService>(ScoreShareService(), permanent: true);
    Get.put<PlayInAppUpdateService>(PlayInAppUpdateService(), permanent: true);
    final storage = Get.find<StorageService>();
    Get.put<SettingsController>(
      SettingsController(storage: storage),
      permanent: true,
    );
  }
}

