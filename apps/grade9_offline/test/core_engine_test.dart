import 'package:flutter_test/flutter_test.dart';
import 'package:grade9_offline_learning/core/sm2.dart';
import 'package:grade9_offline_learning/core/spell_checker.dart';

void main() {
  group('SM-2 scheduler', () {
    const scheduler = Sm2Scheduler();
    final now = DateTime(2026, 11, 9, 12);

    test('first successful recall schedules one day', () {
      final result = scheduler.review(
        difficulty: 4,
        previousRepetitions: 0,
        previousIntervalDays: 0,
        previousEaseFactor: 2.5,
        reviewedAt: now,
      );
      expect(result.intervalDays, 1);
      expect(result.repetitions, 1);
      expect(result.dueAt, DateTime(2026, 11, 10));
    });

    test('second successful recall schedules six days', () {
      final result = scheduler.review(
        difficulty: 5,
        previousRepetitions: 1,
        previousIntervalDays: 1,
        previousEaseFactor: 2.5,
        reviewedAt: now,
      );
      expect(result.intervalDays, 6);
      expect(result.repetitions, 2);
    });

    test('failed recall resets repetitions', () {
      final result = scheduler.review(
        difficulty: 1,
        previousRepetitions: 8,
        previousIntervalDays: 30,
        previousEaseFactor: 2.5,
        reviewedAt: now,
      );
      expect(result.intervalDays, 1);
      expect(result.repetitions, 0);
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('rejects invalid difficulty', () {
      expect(
        () => scheduler.review(
          difficulty: 0,
          previousRepetitions: 0,
          previousIntervalDays: 0,
          previousEaseFactor: 2.5,
          reviewedAt: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Offline spelling engine', () {
    final checker = OfflineSpellChecker(
      ['photosynthesis', 'algorithm', 'electromagnetism', 'physics'],
    );

    test('recognizes exact words case-insensitively', () {
      expect(checker.contains('PHYSICS'), isTrue);
    });

    test('suggests a close correction', () {
      final suggestions = checker.suggest('algoritm');
      expect(suggestions, isNotEmpty);
      expect(suggestions.first.word, 'algorithm');
    });

    test('returns no suggestions for an exact match', () {
      expect(checker.suggest('algorithm'), isEmpty);
    });

    test('Levenshtein distance handles substitutions and insertions', () {
      expect(OfflineSpellChecker.levenshtein('cat', 'cut'), 1);
      expect(OfflineSpellChecker.levenshtein('book', 'books'), 1);
    });
  });
}
