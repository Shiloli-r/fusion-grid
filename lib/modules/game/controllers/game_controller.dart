import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/settings_controller.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/best_run.dart';
import '../../../data/services/storage_service.dart';
import '../engine/game_engine.dart';
import '../models/board_state.dart';
import '../models/game_mode.dart';
import '../models/game_step_result.dart';
import '../models/move_direction.dart';
import '../models/tile.dart';

class GameController extends GetxController {
  final GameMode mode;

  GameController({GameMode? mode}) : mode = mode ?? GameModes.classic;

  // Reactive UI state.
  final RxInt score = 0.obs;
  final RxInt bestScore = 0.obs;
  final RxInt bestSteps = 0.obs;
  final RxInt bestDurationSeconds = 0.obs;
  final RxInt steps = 0.obs;
  final RxInt elapsedSeconds = 0.obs;

  final RxBool showWinOverlay = false.obs;
  final RxBool showGameOverOverlay = false.obs;
  final RxBool hasWon = false.obs;
  final RxInt targetValue = AppConstants.defaultTargetValue.obs;
  final RxInt timeRemainingSeconds = 0.obs;
  final RxString gameOverMessage = ''.obs;
  final RxBool gameOverNewPersonalBest = false.obs;

  final RxList<Tile> tiles = <Tile>[].obs;

  final RxBool canUndo = false.obs;
  final RxBool canShuffle = true.obs;

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
  Timer? _timeAttackTimer;
  Timer? _elapsedTimer;

  _GameSnapshot? _undoSnapshot;

  /// Best score at the start of this round (used to detect a new record at game over).
  int _bestScoreAtRoundStart = 0;

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
    await _migrateLegacyBestIfNeeded();
    final bestRun = await _storage.getBestRun(modeId: mode.id);
    bestScore.value = bestRun.score;
    bestSteps.value = bestRun.steps;
    bestDurationSeconds.value = bestRun.durationSeconds;
    restartGame(showSpawnAnimation: true);
  }

  Future<void> _migrateLegacyBestIfNeeded() async {
    // One-time migration: old versions stored a single global best score.
    final legacy = await _storage.getLegacyBestScore();
    if (legacy <= 0) return;

    final existing = await _storage.getBestRun(modeId: GameModes.classic.id);
    if (existing.score < legacy) {
      await _storage.setBestRun(
        modeId: GameModes.classic.id,
        run: BestRun(score: legacy, steps: existing.steps, durationSeconds: existing.durationSeconds),
      );
    }
    await _storage.clearLegacyBestScore();
  }

  void restartGame({bool showSpawnAnimation = true}) {
    _stopTimeAttack();
    _stopElapsedTimer();
    _pendingGameOverAfterWin = false;
    _latestEffectClearToken = 0;
    _undoSnapshot = null;
    canUndo.value = false;
    canShuffle.value = true;
    showWinOverlay.value = false;
    showGameOverOverlay.value = false;
    hasWon.value = false;
    gameOverMessage.value = '';
    gameOverNewPersonalBest.value = false;

    _bestScoreAtRoundStart = bestScore.value;

    score.value = 0;
    steps.value = 0;
    elapsedSeconds.value = 0;
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

    _startTimeAttackIfNeeded();
    _startElapsedTimer();
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
      spawnFourChance: mode.fourChance,
      nextTileId: _nextTileId,
      effectToken: token,
    );

    if (!result.didMove) return;

    _undoSnapshot = snapshot;
    canUndo.value = true;

    steps.value += 1;

    _board = result.board;
    _nextTileId = result.nextTileId;

    if (result.scoreDelta > 0) {
      score.value += result.scoreDelta;
      _maybeUpdateBestRun();
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
    steps.value = snap.steps;
    elapsedSeconds.value = snap.elapsedSeconds;

    showWinOverlay.value = snap.showWinOverlay;
    showGameOverOverlay.value = snap.showGameOverOverlay;
    hasWon.value = snap.hasWon;

    _nextTileId = snap.nextTileId;
    _moveToken = snap.moveToken;
    _latestEffectClearToken = snap.latestEffectClearToken;
    _pendingGameOverAfterWin = snap.pendingGameOverAfterWin;
    timeRemainingSeconds.value = snap.timeRemainingSeconds;
    gameOverMessage.value = snap.gameOverMessage;
    gameOverNewPersonalBest.value = snap.gameOverNewPersonalBest;
    canShuffle.value = snap.canShuffle;

    tiles.assignAll(_board.tiles);
    _ensureTimeAttackTimerRunning();
    _ensureElapsedTimerRunning();
  }

  void useShufflePowerUp() {
    if (!canShuffle.value) return;
    if (_board.tiles.length < 2) return;

    final sourceTiles = List<Tile>.from(_board.tiles);
    sourceTiles.shuffle(_engine.random);

    final allCells = <(int, int)>[];
    for (var r = 0; r < _board.size; r++) {
      for (var c = 0; c < _board.size; c++) {
        allCells.add((r, c));
      }
    }
    allCells.shuffle(_engine.random);

    final token = _moveToken++;
    final grid = List<List<Tile?>>.generate(
      _board.size,
      (_) => List<Tile?>.filled(_board.size, null, growable: false),
      growable: false,
    );

    for (var i = 0; i < sourceTiles.length; i++) {
      final tile = sourceTiles[i];
      final cell = allCells[i];
      final nr = cell.$1;
      final nc = cell.$2;
      grid[nr][nc] = tile.copyWith(
        row: nr,
        col: nc,
        prevRow: tile.row,
        prevCol: tile.col,
        effect: TileEffectType.spawned,
        effectToken: token,
      );
    }

    _board = BoardState(size: _board.size, grid: grid);
    canShuffle.value = false;
    tiles.assignAll(_board.tiles);
    _scheduleClearEffectsForToken(token);

    showGameOverOverlay.value = false;
    gameOverMessage.value = '';
    gameOverNewPersonalBest.value = false;
    hasWon.value = _board.tiles.any((t) => t.value >= targetValue.value);

    if (!_board.hasValidMoves()) {
      _presentGameOver(message: 'No moves left. Your score: ${score.value}');
      _stopTimeAttack();
      return;
    }

    _ensureTimeAttackTimerRunning();
    _resumeElapsedTimerIfNeeded();
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
      _presentGameOver(message: 'No moves left. Your score: ${score.value}');
      _stopTimeAttack();
    }
  }

  void _presentGameOver({required String message}) {
    gameOverMessage.value = message;
    gameOverNewPersonalBest.value = score.value > _bestScoreAtRoundStart;
    showGameOverOverlay.value = true;
    _stopElapsedTimer();
    _maybeUpdateBestRun();
  }

  void continueAfterWin() {
    showWinOverlay.value = false;
    if (_pendingGameOverAfterWin) {
      _pendingGameOverAfterWin = false;
      _presentGameOver(message: 'No moves left. Your score: ${score.value}');
      return;
    }
    _resumeElapsedTimerIfNeeded();
  }

  void onNewGamePressed() {
    restartGame(showSpawnAnimation: true);
  }

  void _startTimeAttackIfNeeded() {
    final duration = mode.durationSeconds;
    if (duration == null) {
      timeRemainingSeconds.value = 0;
      return;
    }

    timeRemainingSeconds.value = duration;
    _ensureTimeAttackTimerRunning();
  }

  void _ensureTimeAttackTimerRunning() {
    if (mode.durationSeconds == null) return;
    if (_timeAttackTimer != null) return;
    if (timeRemainingSeconds.value <= 0) return;

    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (showGameOverOverlay.value || showWinOverlay.value) return;
      if (timeRemainingSeconds.value <= 1) {
        timeRemainingSeconds.value = 0;
        timer.cancel();
        _timeAttackTimer = null;
        _presentGameOver(message: 'Time is up! Your score: ${score.value}');
        return;
      }
      timeRemainingSeconds.value -= 1;
    });
  }

  void _stopTimeAttack() {
    _timeAttackTimer?.cancel();
    _timeAttackTimer = null;
  }

  void _maybeUpdateBestRun() async {
    final currentScore = score.value;
    if (currentScore <= bestScore.value) return;

    final run = BestRun(score: currentScore, steps: steps.value, durationSeconds: elapsedSeconds.value);
    bestScore.value = currentScore;
    bestSteps.value = run.steps;
    bestDurationSeconds.value = run.durationSeconds;
    await _storage.setBestRun(modeId: mode.id, run: run);
  }

  void _startElapsedTimer() {
    _ensureElapsedTimerRunning();
  }

  void _ensureElapsedTimerRunning() {
    if (_elapsedTimer != null) return;
    if (_isOverlayBlockingInput) return;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isOverlayBlockingInput) return;
      elapsedSeconds.value += 1;
    });
  }

  void _resumeElapsedTimerIfNeeded() {
    if (_isOverlayBlockingInput) return;
    if (_elapsedTimer != null) return;
    _ensureElapsedTimerRunning();
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
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

    final spawnValue = _nextSpawnValue();

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

  int _nextSpawnValue() {
    return _engine.random.nextDouble() < mode.fourChance ? 4 : 2;
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

  @override
  void onClose() {
    _stopTimeAttack();
    _stopElapsedTimer();
    super.onClose();
  }
}

class _GameSnapshot {
  final BoardState board;
  final int score;
  final int steps;
  final int elapsedSeconds;

  final bool showWinOverlay;
  final bool showGameOverOverlay;
  final bool hasWon;

  final int nextTileId;
  final int moveToken;
  final int latestEffectClearToken;
  final bool pendingGameOverAfterWin;
  final int timeRemainingSeconds;
  final String gameOverMessage;
  final bool gameOverNewPersonalBest;
  final bool canShuffle;

  const _GameSnapshot({
    required this.board,
    required this.score,
    required this.steps,
    required this.elapsedSeconds,
    required this.showWinOverlay,
    required this.showGameOverOverlay,
    required this.hasWon,
    required this.nextTileId,
    required this.moveToken,
    required this.latestEffectClearToken,
    required this.pendingGameOverAfterWin,
    required this.timeRemainingSeconds,
    required this.gameOverMessage,
    required this.gameOverNewPersonalBest,
    required this.canShuffle,
  });

  factory _GameSnapshot.fromController({
    required GameController controller,
    required BoardState board,
  }) {
    return _GameSnapshot(
      board: board,
      score: controller.score.value,
      steps: controller.steps.value,
      elapsedSeconds: controller.elapsedSeconds.value,
      showWinOverlay: controller.showWinOverlay.value,
      showGameOverOverlay: controller.showGameOverOverlay.value,
      hasWon: controller.hasWon.value,
      nextTileId: controller._nextTileId,
      moveToken: controller._moveToken,
      latestEffectClearToken: controller._latestEffectClearToken,
      pendingGameOverAfterWin: controller._pendingGameOverAfterWin,
      timeRemainingSeconds: controller.timeRemainingSeconds.value,
      gameOverMessage: controller.gameOverMessage.value,
      gameOverNewPersonalBest: controller.gameOverNewPersonalBest.value,
      canShuffle: controller.canShuffle.value,
    );
  }
}
