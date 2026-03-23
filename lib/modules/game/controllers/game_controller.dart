import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/settings_controller.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/services/storage_service.dart';
import '../engine/game_engine.dart';
import '../models/board_state.dart';
import '../models/game_step_result.dart';
import '../models/move_direction.dart';
import '../models/tile.dart';

class GameController extends GetxController {
  // Reactive UI state.
  final RxInt score = 0.obs;
  final RxInt bestScore = 0.obs;

  final RxBool showWinOverlay = false.obs;
  final RxBool showGameOverOverlay = false.obs;
  final RxBool hasWon = false.obs;
  final RxInt targetValue = AppConstants.defaultTargetValue.obs;

  final RxList<Tile> tiles = <Tile>[].obs;

  final RxBool canUndo = false.obs;

  // Engine internals.
  late final StorageService _storage;
  late final SettingsController _settingsController;
  late final GameEngine _engine;

  BoardState _board = BoardState.empty(AppConstants.boardSize);
  int _nextTileId = 1;
  int _moveToken = 1;

  int _latestEffectClearToken = 0;
  bool _pendingGameOverAfterWin = false;
  bool? _hasVibrator;

  _GameSnapshot? _undoSnapshot;

  bool get _isOverlayBlockingInput =>
      showWinOverlay.value || showGameOverOverlay.value;

  @override
  void onInit() {
    super.onInit();

    _storage = Get.find<StorageService>();
    _settingsController = Get.find<SettingsController>();

    // Random is intentionally injected once so animations remain smooth and
    // board generation feels consistent.
    final random = Random();
    _engine = GameEngine(size: AppConstants.boardSize, random: random);

    unawaited(_primeVibrationCapability());
    _loadBestScoreAndStartNewGame();
  }

  Future<void> _loadBestScoreAndStartNewGame() async {
    bestScore.value = await _storage.getBestScore();
    restartGame(showSpawnAnimation: true);
  }

  void restartGame({bool showSpawnAnimation = true}) {
    _pendingGameOverAfterWin = false;
    _latestEffectClearToken = 0;
    _undoSnapshot = null;
    canUndo.value = false;
    showWinOverlay.value = false;
    showGameOverOverlay.value = false;
    hasWon.value = false;

    score.value = 0;
    _board = BoardState.empty(AppConstants.boardSize);
    _nextTileId = 1;
    _moveToken = 1;

    // Initial spawn.
    final token = showSpawnAnimation ? _moveToken++ : 0;
    _board = _spawnTile(
      board: _board,
      tileId: _nextTileId++,
      effect: token == 0 ? TileEffectType.none : TileEffectType.spawned,
      effectToken: token,
    );
    _board = _spawnTile(
      board: _board,
      tileId: _nextTileId++,
      effect: token == 0 ? TileEffectType.none : TileEffectType.spawned,
      effectToken: token,
    );

    tiles.assignAll(_board.tiles);

    if (token != 0) {
      _scheduleClearEffectsForToken(token);
    }
  }

  void onSwipe(MoveDirection direction) {
    if (_isOverlayBlockingInput) return;
    if (showGameOverOverlay.value) return;

    final snapshot = _GameSnapshot.fromController(
      controller: this,
      board: _stripEffectsForSnapshot(_board),
    );

    final token = _moveToken++;

    final result = _engine.applySwipe(
      board: _board,
      direction: direction,
      alreadyWon: hasWon.value,
      targetValue: targetValue.value,
      nextTileId: _nextTileId,
      effectToken: token,
    );

    if (!result.didMove) return;

    _undoSnapshot = snapshot;
    canUndo.value = true;

    _board = result.board;
    _nextTileId = result.nextTileId;

    if (result.scoreDelta > 0) {
      score.value += result.scoreDelta;
      _maybeUpdateBestScore();
    }

    if (result.didMerge) {
      _playMergeFeedback();
    }

    tiles.assignAll(_board.tiles);
    _scheduleClearEffectsForToken(token);

    _handleWinAndGameOver(step: result);
  }

  void undoLastMove() {
    final snap = _undoSnapshot;
    if (snap == null) return;

    _undoSnapshot = null;
    canUndo.value = false;

    _board = snap.board;
    score.value = snap.score;

    showWinOverlay.value = snap.showWinOverlay;
    showGameOverOverlay.value = snap.showGameOverOverlay;
    hasWon.value = snap.hasWon;

    _nextTileId = snap.nextTileId;
    _moveToken = snap.moveToken;
    _latestEffectClearToken = snap.latestEffectClearToken;
    _pendingGameOverAfterWin = snap.pendingGameOverAfterWin;

    tiles.assignAll(_board.tiles);
  }

  void _handleWinAndGameOver({required GameStepResult step}) {
    hasWon.value = step.hasWon;

    if (step.winReachedThisMove) {
      showWinOverlay.value = true;
      if (step.isGameOver) {
        _pendingGameOverAfterWin = true;
      } else {
        _pendingGameOverAfterWin = false;
      }
      return;
    }

    if (step.isGameOver) {
      showGameOverOverlay.value = true;
    }
  }

  void continueAfterWin() {
    showWinOverlay.value = false;
    if (_pendingGameOverAfterWin) {
      _pendingGameOverAfterWin = false;
      showGameOverOverlay.value = true;
    }
  }

  void onNewGamePressed() {
    restartGame(showSpawnAnimation: true);
  }

  void _maybeUpdateBestScore() async {
    final newBest = score.value;
    if (newBest <= bestScore.value) return;

    bestScore.value = newBest;
    await _storage.setBestScore(newBest);
  }

  Future<void> _playMergeFeedback() async {
    final AppSettings settings = AppSettings(
      soundEnabled: _settingsController.soundEnabled.value,
      vibrationEnabled: _settingsController.vibrationEnabled.value,
    );

    if (settings.vibrationEnabled) {
      if (await _canVibrate()) {
        Vibration.vibrate(duration: 22);
      }
    }

    if (settings.soundEnabled) {
      // No external assets required: use a system sound for a subtle cue.
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _primeVibrationCapability() async {
    await _canVibrate();
  }

  Future<bool> _canVibrate() async {
    if (_hasVibrator != null) return _hasVibrator!;
    _hasVibrator = await Vibration.hasVibrator();
    return _hasVibrator!;
  }

  void _scheduleClearEffectsForToken(int token) {
    if (token == 0) return;
    _latestEffectClearToken = token;

    Future<void>.delayed(_effectDuration, () {
      if (_latestEffectClearToken != token) return;
      _clearEffectsForToken(token);
    });
  }

  Duration get _effectDuration =>
      const Duration(milliseconds: AppConstants.tileEffectMs);

  void _clearEffectsForToken(int token) {
    final nextGrid = List<List<Tile?>>.generate(
      _board.size,
      (r) => List<Tile?>.from(_board.grid[r]),
      growable: false,
    );

    for (var r = 0; r < _board.size; r++) {
      for (var c = 0; c < _board.size; c++) {
        final t = nextGrid[r][c];
        if (t == null) continue;
        if (t.effectToken != token) continue;

        nextGrid[r][c] = t.copyWith(
          effect: TileEffectType.none,
          effectToken: 0,
        );
      }
    }

    _board = BoardState(size: _board.size, grid: nextGrid);
    tiles.assignAll(_board.tiles);
  }

  BoardState _spawnTile({
    required BoardState board,
    required int tileId,
    required TileEffectType effect,
    required int effectToken,
  }) {
    final empties = board.emptyCells();
    if (empties.isEmpty) return board;

    final pick = empties[(_engine.random.nextInt(empties.length))];
    final r = pick.$1;
    final c = pick.$2;

    final spawnValue = _engine.random.nextInt(10) == 0 ? 4 : 2;

    final grid2 = List<List<Tile?>>.generate(
      board.size,
      (rr) => List<Tile?>.from(board.grid[rr]),
      growable: false,
    );

    grid2[r][c] = Tile(
      id: tileId,
      value: spawnValue,
      row: r,
      col: c,
      prevRow: r,
      prevCol: c,
      effect: effect,
      effectToken: effectToken,
    );

    return BoardState(size: board.size, grid: grid2);
  }

  BoardState _stripEffectsForSnapshot(BoardState board) {
    final nextGrid = List<List<Tile?>>.generate(
      board.size,
      (r) => List<Tile?>.from(board.grid[r]),
      growable: false,
    );

    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        final t = nextGrid[r][c];
        if (t == null) continue;
        nextGrid[r][c] = t.copyWith(
          effect: TileEffectType.none,
          effectToken: 0,
        );
      }
    }

    return BoardState(size: board.size, grid: nextGrid);
  }
}

class _GameSnapshot {
  final BoardState board;
  final int score;

  final bool showWinOverlay;
  final bool showGameOverOverlay;
  final bool hasWon;

  final int nextTileId;
  final int moveToken;
  final int latestEffectClearToken;
  final bool pendingGameOverAfterWin;

  const _GameSnapshot({
    required this.board,
    required this.score,
    required this.showWinOverlay,
    required this.showGameOverOverlay,
    required this.hasWon,
    required this.nextTileId,
    required this.moveToken,
    required this.latestEffectClearToken,
    required this.pendingGameOverAfterWin,
  });

  factory _GameSnapshot.fromController({
    required GameController controller,
    required BoardState board,
  }) {
    return _GameSnapshot(
      board: board,
      score: controller.score.value,
      showWinOverlay: controller.showWinOverlay.value,
      showGameOverOverlay: controller.showGameOverOverlay.value,
      hasWon: controller.hasWon.value,
      nextTileId: controller._nextTileId,
      moveToken: controller._moveToken,
      latestEffectClearToken: controller._latestEffectClearToken,
      pendingGameOverAfterWin: controller._pendingGameOverAfterWin,
    );
  }
}
