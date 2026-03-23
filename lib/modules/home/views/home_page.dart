import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/fusion_colors.dart';
import '../../../core/widgets/fusion_button.dart';
import '../../game/widgets/settings_button.dart';
import '../../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FusionColors.bg0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Fusion Grid',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SettingsButton(compact: true),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Merge numbers. Fuse patterns. Win with style.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: FusionColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: FusionColors.cardBorder.withOpacity(0.45),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            const Text(
                              'Swipe to slide and merge on a 4x4 board.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Reach the target tile (default 2048) to trigger the win overlay.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FusionPrimaryButton(
                          text: 'Play',
                          onPressed: () {
                            Get.toNamed(AppRoutes.game);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Offline • No ads • Local best score',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

