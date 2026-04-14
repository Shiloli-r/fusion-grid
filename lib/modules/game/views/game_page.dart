import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/score_share_service.dart';
import '../../../core/theme/fusion_colors.dart';
import '../../../core/widgets/settings_sheet.dart';
import '../../../routes/app_routes.dart';
import '../controllers/game_controller.dart';
import '../models/game_mode.dart';
import '../models/move_direction.dart';
import '../widgets/board_view.dart';
import '../widgets/game_overlay.dart';
import '../widgets/score_card.dart';
import '../widgets/settings_button.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const double _directionRatio = 1.05;
  static const double _flickVelocityThreshold = 360;

  late final GameController _controller;
  late final ConfettiController _confettiController;
  Worker? _newBestWorker;
  Worker? _winWorker;
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final modeId = args is Map<String, dynamic>
        ? args['modeId'] as String?
        : null;
    final mode = GameModes.fromId(modeId);
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
    _controller = Get.put(GameController(mode: mode));
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _newBestWorker = ever(_controller.gameOverNewPersonalBest, (dynamic v) {
      if (v == true && mounted) {
        _confettiController.play();
      }
    });
    _winWorker = ever(_controller.showWinOverlay, (dynamic v) {
      if (v == true && mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _newBestWorker?.dispose();
    _winWorker?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Offset? _start;
  Offset? _last;
  bool _swipeDispatched = false;

  void _resetGesture() {
    _start = null;
    _last = null;
    _swipeDispatched = false;
  }

  bool _tryDispatchSwipe({required double side, required Velocity? velocity}) {
    if (_swipeDispatched || _start == null || _last == null) return false;

    final delta = _last! - _start!;
    final dx = delta.dx;
    final dy = delta.dy;

    final absDx = dx.abs();
    final absDy = dy.abs();
    final maxDelta = math.max(absDx, absDy);
    if (maxDelta < AppConstants.swipeMinDelta) return false;

    final bool isVertical = absDy >= absDx * _directionRatio;
    final primaryDelta = isVertical ? absDy : absDx;

    // Forgiving displacement threshold scaled to the visible game area.
    final displacementThreshold = (side * 0.012).clamp(
      2.5,
      AppConstants.swipeMinDelta - 1,
    );

    final displacedEnough = primaryDelta >= displacementThreshold;

    final primaryVelocity = velocity == null
        ? 0.0
        : (isVertical
              ? velocity.pixelsPerSecond.dy.abs()
              : velocity.pixelsPerSecond.dx.abs());
    final flickEnough =
        velocity != null && primaryVelocity >= _flickVelocityThreshold;

    if (!displacedEnough && !flickEnough) return false;

    _swipeDispatched = true;
    _start = null;
    _last = null;

    if (!isVertical) {
      _controller.onSwipe(dx > 0 ? MoveDirection.right : MoveDirection.left);
    } else {
      _controller.onSwipe(dy > 0 ? MoveDirection.down : MoveDirection.up);
    }

    return true;
  }

  Future<void> _confirmNewGame() async {
    final shouldRestart = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: FusionColors.bg1,
        title: const Text(
          'Start a new game?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your current board and score will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: FusionColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('New Game'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (shouldRestart == true) {
      _controller.onNewGamePressed();
    }
  }

  String _formatDuration(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _showHowToPlayDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: FusionColors.bg1,
        title: const Text('How to play', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Swipe to slide all tiles. Equal values merge once per move. '
          'After every valid move, one new tile appears.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Get.back<void>(),
            style: FilledButton.styleFrom(
              backgroundColor: FusionColors.accent2,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _bottomActionButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    Color? accentColor,
  }) {
    final enabled = onPressed != null;
    final fg = enabled ? (accentColor ?? Colors.white) : Colors.white38;

    return Material(
      color: FusionColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final side = math.min(
      MediaQuery.sizeOf(context).width,
      MediaQuery.sizeOf(context).height,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final now = DateTime.now();
        final last = _lastBackPressedAt;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          Get.closeAllSnackbars();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await Get.offAllNamed(AppRoutes.home);
          return;
        }

        _lastBackPressedAt = now;
        Get.rawSnackbar(
          messageText: const Text(
            'Press back again to go home',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          backgroundColor: FusionColors.card,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          borderRadius: 14,
          duration: const Duration(seconds: 2),
        );
      },
      child: Scaffold(
        backgroundColor: FusionColors.bg0,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) {
              if (_controller.showWinOverlay.value ||
                  _controller.showGameOverOverlay.value) {
                _resetGesture();
                return;
              }
              _start = d.localPosition;
              _last = d.localPosition;
              _swipeDispatched = false;
            },
            onPanUpdate: (d) {
              _last = d.localPosition;
              if (_controller.showWinOverlay.value ||
                  _controller.showGameOverOverlay.value) {
                return;
              }
              _tryDispatchSwipe(side: side, velocity: null);
            },
            onPanCancel: _resetGesture,
            onPanEnd: (d) {
              if (_controller.showWinOverlay.value ||
                  _controller.showGameOverOverlay.value) {
                _resetGesture();
                return;
              }
              _tryDispatchSwipe(side: side, velocity: d.velocity);
              _resetGesture();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Obx(
                          () => ScoreCard(
                            label: 'Score',
                            value: _controller.score.value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => ScoreCard(
                            label: 'Best',
                            value: _controller.bestScore.value,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Share score',
                        onPressed: () {
                          Get.find<ScoreShareService>().shareSession(
                            sessionScore: _controller.score.value,
                            bestScore: _controller.bestScore.value,
                            sessionSteps: _controller.steps.value,
                            sessionDurationSeconds:
                                _controller.elapsedSeconds.value,
                            bestSteps: _controller.bestSteps.value,
                            bestDurationSeconds:
                                _controller.bestDurationSeconds.value,
                            modeTitle: _controller.mode.title,
                          );
                        },
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: FusionColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: FusionColors.cardBorder.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Target',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${_controller.targetValue.value}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: FusionColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: FusionColors.cardBorder.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _showModePicker,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _controller.mode.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SettingsButton(
                        tooltip: 'Sound & vibration',
                        onPressedOverride: showSettingsSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Obx(
                          () => _statChip(
                            icon: Icons.directions_run_rounded,
                            label: 'Steps',
                            value: '${_controller.steps.value}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => _statChip(
                            icon: Icons.schedule_rounded,
                            label: 'Time',
                            value: _formatDuration(
                              _controller.elapsedSeconds.value,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: FusionColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: FusionColors.cardBorder.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                blurRadius: 14,
                                color: FusionColors.accent.withValues(
                                  alpha: 0.18,
                                ),
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _confirmNewGame,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'New Game',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _bottomActionButton(
                        icon: Icons.help_outline_rounded,
                        text: 'How to play',
                        onPressed: _showHowToPlayDialog,
                      ),
                    ],
                  ),
                  if (_controller.mode.durationSeconds != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Obx(
                      () => _statChip(
                        icon: Icons.timer_outlined,
                        label: 'Time Left',
                        value: _formatDuration(
                          _controller.timeRemainingSeconds.value,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Obx(
                            () => AspectRatio(
                              aspectRatio: 1,
                              child: BoardView(
                                size: AppConstants.boardSize,
                                tiles: _controller.tiles.toList(
                                  growable: false,
                                ),
                                onSwipe: _controller.onSwipe,
                                enableGestures: false,
                              ),
                            ),
                          ),
                          Obx(
                            () => GameOverlay(
                              showWin: _controller.showWinOverlay.value,
                              showGameOver:
                                  _controller.showGameOverOverlay.value,
                              canUndo: _controller.canUndo.value,
                              canShuffle: _controller.canShuffle.value,
                              onUndo: _controller.undoLastMove,
                              onShuffle: _controller.useShufflePowerUp,
                              onShareWin: () {
                                Get.find<ScoreShareService>().shareWin(
                                  modeTitle: _controller.mode.title,
                                  targetValue: _controller.targetValue.value,
                                  sessionScore: _controller.score.value,
                                  sessionSteps: _controller.steps.value,
                                  sessionDurationSeconds:
                                      _controller.elapsedSeconds.value,
                                  bestScore: _controller.bestScore.value,
                                  bestSteps: _controller.bestSteps.value,
                                  bestDurationSeconds:
                                      _controller.bestDurationSeconds.value,
                                );
                              },
                              targetValue: _controller.targetValue.value,
                              gameOverMessage:
                                  _controller.gameOverMessage.value,
                              score: _controller.score.value,
                              bestScore: _controller.bestScore.value,
                              newPersonalBest:
                                  _controller.gameOverNewPersonalBest.value,
                              onShareScore: () {
                                Get.find<ScoreShareService>().shareSession(
                                  sessionScore: _controller.score.value,
                                  bestScore: _controller.bestScore.value,
                                  sessionSteps: _controller.steps.value,
                                  sessionDurationSeconds:
                                      _controller.elapsedSeconds.value,
                                  bestSteps: _controller.bestSteps.value,
                                  bestDurationSeconds:
                                      _controller.bestDurationSeconds.value,
                                  modeTitle: _controller.mode.title,
                                );
                              },
                              onContinue: _controller.continueAfterWin,
                              onRestart: _confirmNewGame,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ConfettiWidget(
                                confettiController: _confettiController,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                shouldLoop: false,
                                emissionFrequency: 0.06,
                                numberOfParticles: 24,
                                maxBlastForce: 40,
                                minBlastForce: 14,
                                gravity: 0.3,
                                colors: const <Color>[
                                  FusionColors.accent,
                                  FusionColors.accent2,
                                  FusionColors.good,
                                  Colors.white,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Obx(
                        () => _bottomActionButton(
                          icon: Icons.shuffle_rounded,
                          text: _controller.canShuffle.value
                              ? 'Shuffle x1'
                              : 'Shuffle used',
                          onPressed: _controller.canShuffle.value
                              ? _controller.useShufflePowerUp
                              : null,
                          accentColor: FusionColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Spacer(),
                      Obx(
                        () => _bottomActionButton(
                          icon: Icons.undo_rounded,
                          text: 'Undo',
                          onPressed: _controller.canUndo.value
                              ? _controller.undoLastMove
                              : null,
                          accentColor: FusionColors.accent2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FusionColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FusionColors.cardBorder.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showModePicker() async {
    await Get.bottomSheet<void>(
      Container(
        decoration: BoxDecoration(
          color: FusionColors.bg1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: FusionColors.cardBorder.withValues(alpha: 0.45),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Switch mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...GameModes.all.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    m.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    m.subtitle,
                    style: const TextStyle(color: Colors.white60, height: 1.25),
                  ),
                  trailing: m.id == _controller.mode.id
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: FusionColors.good,
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                  onTap: () async {
                    if (m.id == _controller.mode.id) {
                      Get.back<void>();
                      return;
                    }
                    final ok = await Get.dialog<bool>(
                      AlertDialog(
                        backgroundColor: FusionColors.bg1,
                        title: const Text(
                          'Switch mode?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Switching modes will start a new game and your current progress will be lost.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Get.back(result: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: FusionColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Switch'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      Get.back<void>(); // close sheet
                      if (Get.isRegistered<GameController>()) {
                        Get.delete<GameController>(force: true);
                      }
                      await Get.offNamed(
                        AppRoutes.game,
                        arguments: <String, dynamic>{'modeId': m.id},
                        preventDuplicates: false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
