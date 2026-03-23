class AppSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  const AppSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  static const AppSettings defaults = AppSettings(
    soundEnabled: true,
    vibrationEnabled: true,
  );
}

