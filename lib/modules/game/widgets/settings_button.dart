import 'package:flutter/material.dart';

import '../../../core/widgets/settings_sheet.dart';

class SettingsButton extends StatelessWidget {
  final bool compact;
  final VoidCallback? onPressedOverride;
  final IconData icon;
  final String? tooltip;

  const SettingsButton({
    super.key,
    this.compact = false,
    this.onPressedOverride,
    this.icon = Icons.tune_rounded,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(
        icon,
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

