import 'board_state.dart';

class GameStepResult {
  final bool didMove;
  final BoardState board;
  final int scoreDelta;
  final bool didMerge;
  final bool didSpawn;
  final bool hasWon;
  final bool winReachedThisMove;
  final bool isGameOver;

  // Used to clear tile effects after animations.
  final int effectToken;

  // Used by controller to keep generating ids.
  final int nextTileId;

  const GameStepResult({
    required this.didMove,
    required this.board,
    required this.scoreDelta,
    required this.didMerge,
    required this.didSpawn,
    required this.hasWon,
    required this.winReachedThisMove,
    required this.isGameOver,
    required this.effectToken,
    required this.nextTileId,
  });
}

