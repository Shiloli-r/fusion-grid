class GameMode {
  final String id;
  final String title;
  final String subtitle;
  final bool isAvailable;

  // Probability (0..1) that a new tile is 4 instead of 2.
  final double fourChance;
  final int? durationSeconds;

  const GameMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isAvailable,
    required this.fourChance,
    this.durationSeconds,
  });
}

class GameModes {
  static const GameMode classic = GameMode(
    id: 'classic',
    title: 'Classic',
    subtitle: 'Most new tiles are 2. Reach 2048 and beyond.',
    isAvailable: true,
    fourChance: 0.10,
    durationSeconds: null,
  );

  static const GameMode foursRush = GameMode(
    id: 'fours_rush',
    title: '4s Rush',
    subtitle: 'New 4 tiles appear more often. Harder, faster games.',
    isAvailable: true,
    fourChance: 0.30,
    durationSeconds: null,
  );

  static const GameMode timed = GameMode(
    id: 'timed',
    title: 'Time Attack',
    subtitle: 'You have 2 minutes. Score as high as you can.',
    isAvailable: true,
    fourChance: 0.10,
    durationSeconds: 120,
  );

  static const List<GameMode> all = <GameMode>[
    classic,
    foursRush,
    timed,
  ];

  static GameMode fromId(String? id) {
    if (id == null) return classic;
    return all.where((m) => m.id == id).firstOrNull ?? classic;
  }
}

