import 'tile.dart';

class BoardState {
  final int size;
  final List<List<Tile?>> grid;

  const BoardState({
    required this.size,
    required this.grid,
  });

  factory BoardState.empty(int size) {
    return BoardState(
      size: size,
      grid: List<List<Tile?>>.generate(
        size,
        (_) => List<Tile?>.filled(size, null, growable: false),
        growable: false,
      ),
    );
  }

  Tile? tileAt(int row, int col) => grid[row][col];

  List<Tile> get tiles {
    final result = <Tile>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final t = grid[r][c];
        if (t != null) result.add(t);
      }
    }
    return result;
  }

  List<List<int>> valuesGrid() {
    final values = List<List<int>>.generate(
      size,
      (_) => List<int>.filled(size, 0, growable: false),
      growable: false,
    );
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        values[r][c] = grid[r][c]?.value ?? 0;
      }
    }
    return values;
  }

  bool anyEmptyCell() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == null) return true;
      }
    }
    return false;
  }

  List<(int row, int col)> emptyCells() {
    final result = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == null) {
          result.add((r, c));
        }
      }
    }
    return result;
  }

  bool hasAnyMergeableNeighbor() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = grid[r][c]?.value;
        if (v == null) continue;
        if (c + 1 < size && grid[r][c + 1]?.value == v) return true;
        if (r + 1 < size && grid[r + 1][c]?.value == v) return true;
      }
    }
    return false;
  }

  bool hasValidMoves() => anyEmptyCell() || hasAnyMergeableNeighbor();

  bool valuesEqual(BoardState other) {
    final a = valuesGrid();
    final b = other.valuesGrid();
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }
}

