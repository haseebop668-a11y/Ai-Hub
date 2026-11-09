/// A deterministic SM-2 scheduler. Quality is mapped from the app's
/// 1..5 difficulty scale to the standard SM-2 0..5 response quality scale.
class ReviewSchedule {
  const ReviewSchedule({
    required this.intervalDays,
    required this.repetitions,
    required this.easeFactor,
    required this.dueAt,
  });

  final int intervalDays;
  final int repetitions;
  final double easeFactor;
  final DateTime dueAt;
}

class Sm2Scheduler {
  const Sm2Scheduler();

  ReviewSchedule review({
    required int difficulty,
    required int previousRepetitions,
    required int previousIntervalDays,
    required double previousEaseFactor,
    required DateTime reviewedAt,
  }) {
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError.value(difficulty, 'difficulty', 'Must be 1..5');
    }
    if (previousRepetitions < 0 || previousIntervalDays < 0) {
      throw ArgumentError('Repetitions and interval cannot be negative.');
    }
    if (!previousEaseFactor.isFinite || previousEaseFactor < 1.3) {
      throw ArgumentError.value(previousEaseFactor, 'previousEaseFactor');
    }

    // Difficulty 1 is a complete lapse; 5 is effortless recall.
    final quality = difficulty;
    final easeDelta = 0.1 -
        (5 - quality) * (0.08 + (5 - quality) * 0.02);
    final nextEase = (previousEaseFactor + easeDelta).clamp(1.3, 3.0).toDouble();

    late final int repetitions;
    late final int interval;
    if (quality < 3) {
      repetitions = 0;
      interval = 1;
    } else {
      repetitions = previousRepetitions + 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (previousIntervalDays * nextEase).round().clamp(1, 36500).toInt();
      }
    }

    return ReviewSchedule(
      intervalDays: interval,
      repetitions: repetitions,
      easeFactor: nextEase,
      dueAt: DateTime(
        reviewedAt.year,
        reviewedAt.month,
        reviewedAt.day,
      ).add(Duration(days: interval)),
    );
  }
}
