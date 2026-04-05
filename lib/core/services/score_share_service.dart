import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/fusion_colors.dart';
import '../theme/fusion_theme.dart';
import '../widgets/high_score_share_card.dart';

/// Builds a shareable **image** (PNG) for social posts, plus a short caption.
class ScoreShareService {
  static const String appName = 'Fusion Grid';

  bool _shareInFlight = false;

  Future<void> shareBestScore(int bestScore) async {
    await _shareImage(
      caption: bestScore > 0
          ? 'My $appName best score is $bestScore. Can you beat it?'
          : 'Playing $appName — beat my next high score!',
      child: HighScoreShareCard(bestScore: bestScore),
    );
  }

  Future<void> shareSession({
    required int sessionScore,
    required int bestScore,
    required String modeTitle,
  }) async {
    await _shareImage(
      caption: '$appName — ${modeScoreLine(sessionScore, bestScore)}',
      child: HighScoreShareCard(
        bestScore: bestScore,
        sessionScore: sessionScore,
        modeTitle: modeTitle,
      ),
    );
  }

  String modeScoreLine(int sessionScore, int bestScore) {
    return 'This run: $sessionScore · Best: $bestScore. Think you can top it?';
  }

  void _dismissShareLoading() {
    if (Get.isDialogOpen == true) {
      Get.back<void>();
    }
  }

  Future<void> _shareImage({
    required String caption,
    required Widget child,
  }) async {
    if (_shareInFlight) return;
    _shareInFlight = true;

    try {
      Get.dialog<void>(
        PopScope(
          canPop: false,
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                final double maxCardW = (MediaQuery.sizeOf(context).width - 48)
                    .clamp(260.0, 340.0);
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardW),
                  child: Material(
                    color: FusionColors.bg1,
                    elevation: 18,
                    shadowColor: Colors.black.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: FusionColors.cardBorder.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 20,
                      ),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          decorationColor: Colors.transparent,
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: FusionColors.accent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Creating your score card…',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  letterSpacing: 0.15,
                                  decoration: TextDecoration.none,
                                  decorationThickness: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
      );

      final ScreenshotController controller = ScreenshotController();
      final Uint8List bytes = await controller.captureFromWidget(
        Theme(
          data: FusionTheme.dark(),
          child: Material(color: Colors.transparent, child: child),
        ),
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3,
        targetSize: const Size(1080, 1350),
        context: Get.context,
      );

      _dismissShareLoading();

      await Share.shareXFiles(<XFile>[
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'fusion_grid_score.png',
        ),
      ], text: caption);
    } catch (_) {
      _dismissShareLoading();
      await Share.share(caption);
    } finally {
      _dismissShareLoading();
      _shareInFlight = false;
    }
  }
}
