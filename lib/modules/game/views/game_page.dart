import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/fusion_colors.dart';
import '../../../core/widgets/fusion_button.dart';
import '../../../core/widgets/settings_sheet.dart';
import '../controllers/game_controller.dart';
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

  final GameController _controller = Get.put(GameController());

  Offset? _start;
  Offset? _last;
  bool _swipeDispatched = false;

  void _resetGesture() {
    _start = null;
    _last = null;
    _swipeDispatched = false;
  }

  bool _tryDispatchSwipe({
    required double side,
    required Velocity? velocity,
  }) {
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
    final displacementThreshold =
        (side * 0.012).clamp(2.5, AppConstants.swipeMinDelta - 1);

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

  @override
  Widget build(BuildContext context) {
    final side =
        math.min(MediaQuery.sizeOf(context).width, MediaQuery.sizeOf(context).height);

    return Scaffold(
      backgroundColor: FusionColors.bg0,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) {
            // Don’t commit gestures when an overlay is blocking.
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: FusionColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: FusionColors.cardBorder.withOpacity(0.35),
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
                  SettingsButton(
                    onPressedOverride: () {
                      showSettingsSheet();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // Dedicated Obx: forces rebuild on tile list updates.
                      Obx(
                        () => AspectRatio(
                          aspectRatio: 1,
                          child: BoardView(
                            size: AppConstants.boardSize,
                            tiles: _controller.tiles.toList(growable: false),
                            onSwipe: _controller.onSwipe,
                            enableGestures: false,
                          ),
                        ),
                      ),
                      Obx(
                        () => GameOverlay(
                          showWin: _controller.showWinOverlay.value,
                          showGameOver: _controller.showGameOverOverlay.value,
                          canUndo: _controller.canUndo.value,
                          onUndo: _controller.undoLastMove,
                          targetValue: _controller.targetValue.value,
                          score: _controller.score.value,
                          bestScore: _controller.bestScore.value,
                          onContinue: _controller.continueAfterWin,
                          onRestart: _controller.onNewGamePressed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FusionSecondaryButton(
                      text: 'New Game',
                        onPressed: _controller.onNewGamePressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => IconButton(
                      tooltip: 'Undo last move',
                      onPressed: _controller.canUndo.value
                          ? _controller.undoLastMove
                          : null,
                      icon: Icon(
                        Icons.undo_rounded,
                        color: _controller.canUndo.value
                            ? FusionColors.accent2
                            : Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Swipe instructions',
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'How to play',
                        middleText:
                            'Swipe to slide all tiles. Equal values merge once per move. After every valid move, one new tile spawns.',
                        textConfirm: 'Got it',
                        confirmTextColor: Colors.white,
                        buttonColor: FusionColors.accent2,
                      );
                    },
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

