import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/fusion_theme.dart';
import '../models/move_direction.dart';
import '../models/tile.dart';
import 'fusion_tile.dart';

class BoardView extends StatefulWidget {
  final List<Tile> tiles;
  final int size;
  final ValueChanged<MoveDirection> onSwipe;
  final bool enableGestures;

  const BoardView({
    super.key,
    required this.tiles,
    required this.size,
    required this.onSwipe,
    this.enableGestures = true,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  static const double _directionRatio = 1.05;
  static const double _flickVelocityThreshold = 320;

  Offset? _start;
  Offset? _last;
  bool _swipeDispatched = false;

  void _resetGesture() {
    _start = null;
    _last = null;
    _swipeDispatched = false;
  }

  bool _tryDispatchSwipe({required double side, Velocity? velocity}) {
    if (_swipeDispatched || _start == null || _last == null) return false;

    final delta = _last! - _start!;
    final dx = delta.dx;
    final dy = delta.dy;
    final absDx = dx.abs();
    final absDy = dy.abs();

    final isVertical = absDy >= absDx * _directionRatio;
    final primaryDelta = isVertical ? absDy : absDx;
    final primaryVelocity = velocity == null
        ? 0.0
        : isVertical
        ? velocity.pixelsPerSecond.dy.abs()
        : velocity.pixelsPerSecond.dx.abs();

    final displacementThreshold = (side * 0.03).clamp(
      4.0,
      AppConstants.swipeMinDelta,
    );

    // Accept swipe if either it's displaced enough or it's a fast flick.
    if (primaryDelta < displacementThreshold &&
        primaryVelocity < _flickVelocityThreshold) {
      return false;
    }

    if (!isVertical) {
      final axisDelta = absDx > 0.001
          ? dx
          : (velocity?.pixelsPerSecond.dx ?? 0);
      if (axisDelta == 0) return false;
      widget.onSwipe(axisDelta > 0 ? MoveDirection.right : MoveDirection.left);
    } else {
      final axisDelta = absDy > 0.001
          ? dy
          : (velocity?.pixelsPerSecond.dy ?? 0);
      if (axisDelta == 0) return false;
      widget.onSwipe(axisDelta > 0 ? MoveDirection.down : MoveDirection.up);
    }

    _swipeDispatched = true;
    _start = null;
    _last = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tileTheme = FusionTheme.tileTheme;
    final gap = tileTheme.tileGap();
    final padding = tileTheme.boardPadding();

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize =
            (side - padding * 2 - gap * (widget.size - 1)) / widget.size;

        final board = SizedBox(
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const <Color>[
                  Color(0xFF240C4B),
                  Color(0xFF090A16),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222A3A), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Stack(
                children: <Widget>[
                  // Subtle grid lines.
                  for (var r = 0; r < widget.size; r++)
                    for (var c = 0; c < widget.size; c++)
                      Positioned(
                        left: c * (cellSize + gap),
                        top: r * (cellSize + gap),
                        width: cellSize,
                        height: cellSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              tileTheme.tileRadius(),
                            ),
                            border: Border.all(
                              color: const Color(0x0DFFFFFF),
                            ),
                          ),
                        ),
                      ),
                  for (final tile in widget.tiles)
                    AnimatedPositioned(
                      key: ValueKey(tile.id),
                      duration: tileTheme.movementDuration(),
                      curve: Curves.easeOutCubic,
                      left: tile.col * (cellSize + gap),
                      top: tile.row * (cellSize + gap),
                      width: cellSize,
                      height: cellSize,
                      child: FusionTileWidget(tile: tile, size: cellSize),
                    ),
                ],
              ),
            ),
          ),
        );

        if (!widget.enableGestures) return board;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) {
            _start = d.localPosition;
            _last = d.localPosition;
            _swipeDispatched = false;
          },
          onPanUpdate: (d) {
            _last = d.localPosition;
            _tryDispatchSwipe(side: side);
          },
          onPanCancel: _resetGesture,
          onPanEnd: (d) {
            if (!_swipeDispatched) {
              _tryDispatchSwipe(side: side, velocity: d.velocity);
            }
            _resetGesture();
          },
          child: board,
        );
      },
    );
  }
}
