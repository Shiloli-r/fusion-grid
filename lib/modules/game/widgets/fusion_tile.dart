import 'package:flutter/material.dart';

import '../../../core/theme/fusion_theme.dart';
import '../../../core/theme/fusion_colors.dart';
import '../models/tile.dart';

class FusionTileWidget extends StatefulWidget {
  final Tile tile;
  final double size;

  const FusionTileWidget({
    super.key,
    required this.tile,
    required this.size,
  });

  @override
  State<FusionTileWidget> createState() => _FusionTileWidgetState();
}

class _FusionTileWidgetState extends State<FusionTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int? _lastEffectToken;
  TileEffectType _lastEffect = TileEffectType.none;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FusionTheme.tileTheme.effectDuration(),
    );
    _scaleAnimation = _controller.drive(Tween<double>(begin: 1.0, end: 1.0));
    if (widget.tile.effect != TileEffectType.none) {
      _playEffect(widget.tile.effect, widget.tile.effectToken);
    }
  }

  @override
  void didUpdateWidget(covariant FusionTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRestart =
        widget.tile.effectToken != _lastEffectToken || widget.tile.effect != _lastEffect;

    if (shouldRestart && widget.tile.effect != TileEffectType.none) {
      _playEffect(widget.tile.effect, widget.tile.effectToken);
    } else if (widget.tile.effect == TileEffectType.none) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  void _playEffect(TileEffectType effect, int token) {
    _lastEffectToken = token;
    _lastEffect = effect;
    final tween = switch (effect) {
      TileEffectType.spawned => TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween(begin: 0.25, end: 1.08).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
            weight: 60,
          ),
          TweenSequenceItem<double>(
            tween: Tween(begin: 1.08, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            ),
            weight: 40,
          ),
        ]),
      TileEffectType.merged => TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween(begin: 1.0, end: 1.18).chain(
              CurveTween(curve: Curves.easeOutBack),
            ),
            weight: 55,
          ),
          TweenSequenceItem<double>(
            tween: Tween(begin: 1.18, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            ),
            weight: 45,
          ),
        ]),
      TileEffectType.none => TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween(begin: 1.0, end: 1.0),
            weight: 1,
          ),
        ]),
    };

    _scaleAnimation = _controller.drive(tween);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FusionTheme.tileTheme;
    final baseBg = theme.backgroundForValue(widget.tile.value);
    final mergedBg = theme.mergedBackgroundForValue(widget.tile.value);
    final spawnedBg = theme.spawnedBackgroundForValue(widget.tile.value);
    final textStyle = theme.textStyleForValue(widget.tile.value);
    final border = theme.borderForValue(widget.tile.value);

    final bool isMerged = widget.tile.effect == TileEffectType.merged;
    final bool isSpawned = widget.tile.effect == TileEffectType.spawned;

    final bg = isMerged ? mergedBg : isSpawned ? spawnedBg : baseBg;
    final mergedBorder = isMerged ? mergedBg.withValues(alpha: 0.75) : null;
    final spawnedBorder = isSpawned ? spawnedBg.withValues(alpha: 0.45) : null;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(theme.tileRadius()),
        border: Border.all(
          color: (mergedBorder ??
              spawnedBorder ??
              border ??
              FusionColors.cardBorder.withValues(alpha: 0.35)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 14,
            spreadRadius: 0,
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 10),
          ),
          if (isMerged)
            BoxShadow(
              blurRadius: 26,
              spreadRadius: 0,
              color: mergedBg.withValues(alpha: 0.35),
              offset: const Offset(0, 0),
            ),
          if (isSpawned)
            BoxShadow(
              blurRadius: 22,
              spreadRadius: 0,
              color: spawnedBg.withValues(alpha: 0.25),
              offset: const Offset(0, 0),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${widget.tile.value}',
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );

    if (widget.tile.effect == TileEffectType.none) return child;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      child: child,
      builder: (context, childWidget) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: childWidget,
        );
      },
    );
  }
}

