import 'package:flutter/material.dart';

import '../../../core/theme/fusion_colors.dart';
import '../../../core/widgets/fusion_button.dart';

class GameOverlay extends StatelessWidget {
  final bool showWin;
  final bool showGameOver;
  final bool canUndo;
  final bool canShuffle;
  final VoidCallback? onUndo;
  final VoidCallback? onShuffle;
  final int targetValue;
  final String? gameOverMessage;
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final int score;
  final int bestScore;

  const GameOverlay({
    super.key,
    required this.showWin,
    required this.showGameOver,
    required this.canUndo,
    required this.canShuffle,
    required this.onUndo,
    required this.onShuffle,
    required this.targetValue,
    this.gameOverMessage,
    required this.onContinue,
    required this.onRestart,
    required this.score,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final show = showWin || showGameOver;
    if (!show) return const SizedBox.shrink();

    final title = showWin ? 'Target Reached' : 'Game Over';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.52),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FusionColors.bg1,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FusionColors.cardBorder.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      showWin
                          ? 'You reached $targetValue. Keep going!'
                          : (gameOverMessage?.isNotEmpty == true
                              ? gameOverMessage!
                              : 'No moves left. Your score: $score'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Best: $bestScore',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showWin)
                      Row(
                        children: <Widget>[
                          if (canShuffle && onShuffle != null)
                            Expanded(
                              child: FusionSecondaryButton(
                                text: 'Shuffle',
                                onPressed: onShuffle!,
                              ),
                            ),
                          if (canShuffle && onShuffle != null) const SizedBox(width: 12),
                          if (canUndo && onUndo != null)
                            Expanded(
                              child: FusionSecondaryButton(
                                text: 'Undo',
                                onPressed: onUndo!,
                              ),
                            ),
                          if (canUndo && onUndo != null) const SizedBox(width: 12),
                          Expanded(
                            child: FusionSecondaryButton(
                              text: 'Continue',
                              onPressed: onContinue,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: <Widget>[
                          if (canShuffle && onShuffle != null)
                            Expanded(
                              child: FusionSecondaryButton(
                                text: 'Shuffle',
                                onPressed: onShuffle!,
                              ),
                            ),
                          if (canShuffle && onShuffle != null) const SizedBox(width: 12),
                          if (canUndo && onUndo != null)
                            Expanded(
                              child: FusionSecondaryButton(
                                text: 'Undo',
                                onPressed: onUndo!,
                              ),
                            ),
                          if (canUndo && onUndo != null) const SizedBox(width: 12),
                          Expanded(
                            child: FusionPrimaryButton(
                              text: 'New Game',
                              onPressed: onRestart,
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
      ),
    );
  }
}

