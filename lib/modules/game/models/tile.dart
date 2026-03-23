enum TileEffectType {
  none,
  spawned,
  merged,
}

class Tile {
  final int id;
  final int value;
  final int row;
  final int col;

  // These are useful if you later add explicit tweened animations
  // independent of layout changes. For the MVP, Flutter's keyed widgets
  // handle movement animations automatically, but we keep the data to
  // make animation logic manageable.
  final int prevRow;
  final int prevCol;

  final TileEffectType effect;
  final int effectToken;

  const Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    required this.prevRow,
    required this.prevCol,
    required this.effect,
    required this.effectToken,
  });

  Tile copyWith({
    int? id,
    int? value,
    int? row,
    int? col,
    int? prevRow,
    int? prevCol,
    TileEffectType? effect,
    int? effectToken,
  }) {
    return Tile(
      id: id ?? this.id,
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      prevRow: prevRow ?? this.prevRow,
      prevCol: prevCol ?? this.prevCol,
      effect: effect ?? this.effect,
      effectToken: effectToken ?? this.effectToken,
    );
  }
}

