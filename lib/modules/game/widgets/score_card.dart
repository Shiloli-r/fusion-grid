import 'package:flutter/material.dart';

import '../../../core/theme/fusion_colors.dart';

class ScoreCard extends StatelessWidget {
  final String label;
  final int value;

  const ScoreCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FusionColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FusionColors.cardBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

