class BestRun {
  final int score;
  final int steps;
  final int durationSeconds;

  const BestRun({
    required this.score,
    required this.steps,
    required this.durationSeconds,
  });

  static const BestRun empty = BestRun(score: 0, steps: 0, durationSeconds: 0);
}

