import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'fusion_colors.dart';

class FusionTheme {
  static ThemeData dark() {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: FusionColors.bg0,
      canvasColor: FusionColors.bg0,
      primaryColor: FusionColors.accent,
      colorScheme: base.colorScheme.copyWith(
        primary: FusionColors.accent,
        secondary: FusionColors.accent2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.3,
          color: Colors.white70,
        ),
      ),
    );
  }

  static final FusionTileTheme tileTheme = FusionTileTheme._();
}

class FusionTileTheme {
  FusionTileTheme._();

  // Dedicated palette: each power-of-two value gets its own distinct color.
  // Index 0 corresponds to value 2, index 1 to value 4, etc.
  static const List<Color> tilePalette = <Color>[
    Color(0xFFC8B4FF), // 2
    Color(0xFF6EE7FF), // 4
    Color(0xFFFF8AD8), // 8
    Color(0xFF9DFF8A), // 16
    Color(0xFF6D79FF), // 32
    Color(0xFF35D7FF), // 64
    Color(0xFF22C7FF), // 128
    Color(0xFF4EE29A), // 256
    Color(0xFFB34CFF), // 512
    Color(0xFFEA5CFF), // 1024
    Color(0xFFC45CFF), // 2048
    Color(0xFFFF74D8), // 4096
    Color(0xFF75E7FF), // 8192+
  ];

  int _idxForValue(int value) {
    final log2 = (math.log(value) / math.ln2).round();
    return (log2 - 1);
  }

  Color backgroundForValue(int value) {
    if (value <= 0) return FusionColors.card;

    final idx = _idxForValue(value).clamp(0, tilePalette.length);
    if (idx < tilePalette.length) return tilePalette[idx];

    // For extremely large tiles: keep hue but gently move towards accent2.
    final t = (idx - (tilePalette.length - 1)).clamp(0, 6) / 6.0;
    return Color.lerp(tilePalette.last, FusionColors.accent2, t.toDouble())!;
  }

  Color mergedBackgroundForValue(int value) {
    // Brighten the tile while preserving its per-value hue.
    final base = backgroundForValue(value);
    return Color.lerp(base, Colors.white, 0.42)!;
  }

  Color spawnedBackgroundForValue(int value) {
    // Slightly lift toward the app accent; keep spawn feeling subtle.
    final base = backgroundForValue(value);
    return Color.lerp(base, FusionColors.accent, 0.10)!;
  }

  Color? borderForValue(int value) {
    if (value <= 0) return null;
    // Value-specific border gives tiles a crisp edge without looking flat.
    final base = backgroundForValue(value);
    return base.withValues(alpha: 0.30);
  }

  Color textColorForValue(int value) {
    final idx = _idxForValue(value);
    return idx >= 4 ? FusionColors.tileTextLight : FusionColors.tileTextDark;
  }

  TextStyle textStyleForValue(int value) {
    final idx = _idxForValue(value);
    final size = (idx <= 1) ? 22.0 : (idx <= 3) ? 20.0 : 18.0;

    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: textColorForValue(value),
      height: 1.0,
      shadows: (idx >= 4)
          ? const <Shadow>[
              Shadow(
                blurRadius: 8,
                color: Color(0x33000000),
                offset: Offset(0, 2),
              )
            ]
          : null,
    );
  }

  double tileRadius() => 18.0;

  double tileGap() => 12.0;

  double boardPadding() => 14.0;

  Duration movementDuration() => const Duration(milliseconds: AppConstants.moveAnimationMs);

  Duration effectDuration() => const Duration(milliseconds: AppConstants.tileEffectMs);
}

