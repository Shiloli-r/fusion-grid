class AppConstants {
  static const int boardSize = 4;
  static const int defaultTargetValue = 2048;

  // Animation timing targets. These are used both for UI durations and for
  // clearing tile effects in the controller.
  static const int moveAnimationMs = 160;
  static const int tileEffectMs = 240;

  // Swipe detection.
  // Minimum swipe displacement before we decide a swipe occurred.
  // Keep this fairly low; we also use velocity + relative thresholds in the UI.
  static const double swipeMinDelta = 6.0;
}

