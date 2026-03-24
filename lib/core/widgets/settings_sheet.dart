import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/controllers/settings_controller.dart';
import '../theme/fusion_colors.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Subtle system clicks on merges'),
                value: controller.soundEnabled.value,
                activeThumbColor: FusionColors.accent2,
                onChanged: (v) => controller.setSoundEnabled(v),
              ),
            ),
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibration', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Haptics on merges'),
                value: controller.vibrationEnabled.value,
                activeThumbColor: FusionColors.accent,
                onChanged: (v) => controller.setVibrationEnabled(v),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: FusionColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSettingsSheet() async {
  return Get.bottomSheet(
    const SettingsSheet(),
    isScrollControlled: false,
    backgroundColor: FusionColors.bg1,
  );
}

