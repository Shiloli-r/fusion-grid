import 'package:flutter/material.dart';

import '../../../core/widgets/settings_sheet.dart';

class SettingsButton extends StatelessWidget {
  final bool compact;
  final VoidCallback? onPressedOverride;

  const SettingsButton({
    super.key,
    this.compact = false,
    this.onPressedOverride,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings_rounded,
        color: Colors.white.withValues(alpha: 0.9),
      ),
      splashRadius: compact ? 18 : 22,
      onPressed: onPressedOverride ??
          () {
            showSettingsSheet();
          },
    );
  }
}

