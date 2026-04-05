import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';

import '../theme/fusion_colors.dart';

/// Google Play [In-App Updates](https://developer.android.com/guide/playcore/in-app-updates).
/// Only runs on Android; no-ops elsewhere. Sideloaded/debug builds typically fail silently.
class PlayInAppUpdateService {
  PlayInAppUpdateService();

  StreamSubscription<InstallStatus>? _installSub;
  bool _flexibleDialogOpen = false;

  /// Call once after the first screen is shown (cold start).
  Future<void> checkOnLaunch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    // Widget/integration tests: no Play Store; channel can hang.
    final String binding = SchedulerBinding.instance.runtimeType.toString();
    if (binding.contains('Test')) return;

    await _installSub?.cancel();
    _installSub = null;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final bool highPriority = info.updatePriority >= 4;

      if (highPriority && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
        if (result != AppUpdateResult.success) return;

        _installSub = InAppUpdate.installUpdateListener.listen((InstallStatus status) {
          if (status == InstallStatus.downloaded) {
            unawaited(_showFlexibleReadyDialog());
          }
        });
        return;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Not from Play (local install), emulator quirks, etc.
    }
  }

  Future<void> _showFlexibleReadyDialog() async {
    await _installSub?.cancel();
    _installSub = null;

    if (_flexibleDialogOpen) return;
    _flexibleDialogOpen = true;
    try {
      await Get.dialog<void>(
        AlertDialog(
          backgroundColor: FusionColors.bg1,
          title: const Text(
            'Update ready',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'The latest version has finished downloading. Restart now to install it.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back<void>(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Get.back<void>();
                try {
                  await InAppUpdate.completeFlexibleUpdate();
                } catch (_) {}
              },
              style: FilledButton.styleFrom(
                backgroundColor: FusionColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restart'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      _flexibleDialogOpen = false;
    }
  }
}
