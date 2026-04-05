import 'package:flutter/material.dart';

import '../theme/fusion_colors.dart';

/// Fixed 1080×1350 (4:5) layout for exporting a PNG to Instagram / X / etc.
/// Replace [assets/share/share_background.png] with your own full-bleed artwork anytime.
class HighScoreShareCard extends StatelessWidget {
  const HighScoreShareCard({
    super.key,
    required this.bestScore,
    this.sessionScore,
    this.modeTitle,
  });

  final int bestScore;
  final int? sessionScore;
  final String? modeTitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1080,
      height: 1350,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/share/share_background.png',
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF2D1850),
                      FusionColors.bg0,
                      Color(0xFF0A0514),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 720,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 72, 56, 88),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 3),
                Text(
                  'Fusion Grid',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  '$bestScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 132,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PERSONAL BEST',
                  style: TextStyle(
                    color: FusionColors.accent2.withValues(alpha: 0.95),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                if (sessionScore != null) ...<Widget>[
                  const SizedBox(height: 48),
                  Text(
                    'This run',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$sessionScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                if (modeTitle != null && modeTitle!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: FusionColors.accent.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      modeTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
