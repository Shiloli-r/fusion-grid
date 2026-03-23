import 'package:get/get.dart';

import '../core/controllers/settings_controller.dart';
import '../data/services/storage_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    final storage = Get.find<StorageService>();
    Get.put<SettingsController>(
      SettingsController(storage: storage),
      permanent: true,
    );
  }
}

