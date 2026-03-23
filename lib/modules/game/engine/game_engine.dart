import 'dart:math';

import '../models/board_state.dart';
import '../models/game_step_result.dart';
import '../models/move_direction.dart';
import '../models/tile.dart';

class GameEngine {
  final int size;
  final Random random;

  GameEngine({
    required this.size,
    required this.random,
  });

  GameStepResult applySwipe({
    required BoardState board,
    required MoveDirection direction,
    required bool alreadyWon,
    required int targetValue,
    required int nextTileId,
    required int effectToken,
  }) {
    final oldValues = board.valuesGrid();

    final newGrid = List<List<Tile?>>.generate(
      size,
      (_) => List<Tile?>.filled(size, null, growable: false),
      growable: false,
    );

    var scoreDelta = 0;
    var didMerge = false;

    for (var line = 0; line < size; line++) {
      final tilesInOrder = <Tile>[];

      // Collect tiles in traversal order for the chosen direction.
      for (var idx = 0; idx < size; idx++) {
        final (r, c) = _cellForTraversal(direction, line: line, idx: idx, size: size);
        final t = board.tileAt(r, c);
        if (t != null) tilesInOrder.add(t);
      }

      var target = 0;
      var i = 0;
      while (i < tilesInOrder.length) {
        final current = tilesInOrder[i];

        final shouldMerge = i + 1 < tilesInOrder.length &&
            tilesInOrder[i + 1].value == current.value;

        if (shouldMerge) {
          final (fr, fc) = _cellForPlacement(direction, line: line, targetIndex: target, size: size);
          final mergedValue = current.value * 2;

          newGrid[fr][fc] = Tile(
            id: current.id, // Reuse the leading tile id for stable widget keys.
            value: mergedValue,
            row: fr,
            col: fc,
            prevRow: current.row,
            prevCol: current.col,
            effect: TileEffectType.merged,
            effectToken: effectToken,
          );

          scoreDelta += mergedValue;
          didMerge = true;
          target++;
          i += 2;
        } else {
          final (fr, fc) = _cellForPlacement(direction, line: line, targetIndex: target, size: size);

          newGrid[fr][fc] = Tile(
            id: current.id,
            value: current.value,
            row: fr,
            col: fc,
            prevRow: current.row,
            prevCol: current.col,
            effect: TileEffectType.none,
            effectToken: 0,
          );

          target++;
          i += 1;
        }
      }
    }

    final movedBoard = BoardState(size: size, grid: newGrid);
    final didMove = !_valuesEqual(oldValues, movedBoard.valuesGrid());

    if (!didMove) {
      return GameStepResult(
        didMove: false,
        board: board,
        scoreDelta: 0,
        didMerge: false,
        didSpawn: false,
        hasWon: alreadyWon,
        winReachedThisMove: false,
        isGameOver: false,
        effectToken: effectToken,
        nextTileId: nextTileId,
      );
    }

    // Spawn a new tile after a valid move.
    final empties = movedBoard.emptyCells();
    var spawned = false;
    var finalBoard = movedBoard;
    var nextId = nextTileId;

    if (empties.isNotEmpty) {
      final pick = empties[random.nextInt(empties.length)];
      final spawnRow = pick.$1;
      final spawnCol = pick.$2;

      final spawnValue = _spawnValue();
      nextId += 1;

      final spawnTile = Tile(
        id: nextTileId,
        value: spawnValue,
        row: spawnRow,
        col: spawnCol,
        prevRow: spawnRow,
        prevCol: spawnCol,
        effect: TileEffectType.spawned,
        effectToken: effectToken,
      );

      final grid2 = List<List<Tile?>>.generate(
        size,
        (r) => List<Tile?>.from(movedBoard.grid[r]),
        growable: false,
      );
      grid2[spawnRow][spawnCol] = spawnTile;
      finalBoard = BoardState(size: size, grid: grid2);
      spawned = true;
    }

    final hasWon = alreadyWon || finalBoard.tiles.any((t) => t.value >= targetValue);
    final winReachedThisMove = !alreadyWon && hasWon;

    final isGameOver = !finalBoard.hasValidMoves();

    return GameStepResult(
      didMove: true,
      board: finalBoard,
      scoreDelta: scoreDelta,
      didMerge: didMerge,
      didSpawn: spawned,
      hasWon: hasWon,
      winReachedThisMove: winReachedThisMove,
      isGameOver: isGameOver,
      effectToken: effectToken,
      nextTileId: nextId,
    );
  }

  int _spawnValue() {
    // "Usually 2, smaller chance of 4"
    // 0 => 4, otherwise 2.
    return random.nextInt(10) == 0 ? 4 : 2;
  }

  bool _valuesEqual(List<List<int>> a, List<List<int>> b) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  // Traversal maps idx from 0..size-1 along a line into a cell position, based
  // on the swipe direction.
  (int, int) _cellForTraversal(
    MoveDirection direction, {
    required int line,
    required int idx,
    required int size,
  }) {
    switch (direction) {
      case MoveDirection.left:
        return (line, idx);
      case MoveDirection.right:
        return (line, size - 1 - idx);
      case MoveDirection.up:
        return (idx, line);
      case MoveDirection.down:
        return (size - 1 - idx, line);
    }
  }

  // Placement maps the targetIndex (0..size-1) where the next tile should
  // land into a cell position, based on the swipe direction.
  (int, int) _cellForPlacement(
    MoveDirection direction, {
    required int line,
    required int targetIndex,
    required int size,
  }) {
    switch (direction) {
      case MoveDirection.left:
        return (line, targetIndex);
      case MoveDirection.right:
        return (line, size - 1 - targetIndex);
      case MoveDirection.up:
        return (targetIndex, line);
      case MoveDirection.down:
        return (size - 1 - targetIndex, line);
    }
  }
}

