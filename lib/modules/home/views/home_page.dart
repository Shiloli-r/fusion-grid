import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/play_in_app_update_service.dart';
import '../../../core/services/score_share_service.dart';
import '../../../core/theme/fusion_colors.dart';
import '../../../core/widgets/fusion_button.dart';
import '../../../data/services/storage_service.dart';
import '../../game/models/game_mode.dart';
import '../../game/widgets/settings_button.dart';
import '../../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _openingModeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        unawaited(Get.find<PlayInAppUpdateService>().checkOnLaunch());
      });
    });
  }

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
                  const Spacer(),
                  IconButton(
                    tooltip: 'Share best score',
                    onPressed: () async {
                      final best = await Get.find<StorageService>().getBestScore();
                      await Get.find<ScoreShareService>().shareBestScore(best);
                    },
                    icon: const Icon(Icons.share_rounded, color: Colors.white70),
                  ),
                  const SettingsButton(
                    compact: true,
                    tooltip: 'Sound & vibration',
                    icon: Icons.settings_rounded,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            width: 86,
                            height: 86,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: FusionColors.card,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: Colors.white70,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fusion Grid',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                letterSpacing: -0.6,
                                fontSize: 34,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Merge fast. Build high. Stay in flow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF231040),
                                Color(0xFF140B24),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: FusionColors.cardBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Choose a mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...GameModes.all.map((GameMode m) => _modeCard(m)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FusionPrimaryButton(
                            text: 'Play Classic',
                            loading: _openingModeId == GameModes.classic.id,
                            onPressed: () => _openMode(GameModes.classic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Offline • Local best score • More modes coming',
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

  Widget _modeCard(GameMode mode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: FusionColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FusionColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  mode.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mode.subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          mode.isAvailable
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        FusionColors.accent,
                        FusionColors.accent2,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        blurRadius: 14,
                        color: FusionColors.accent.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openingModeId != null
                          ? null
                          : () => _openMode(mode),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (_openingModeId == mode.id)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else ...<Widget>[
                              const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text(
                                'Play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _openMode(GameMode mode) async {
    if (!mode.isAvailable || _openingModeId != null) return;
    setState(() => _openingModeId = mode.id);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await Get.toNamed(
      AppRoutes.game,
      arguments: <String, dynamic>{
        'modeId': mode.id,
      },
    );
    if (mounted) setState(() => _openingModeId = null);
  }
}

