import 'dart:math' as math;

/// The deterministic part of the tutor. It chooses what to study from learner
/// state; a language model may explain material, but never controls scheduling.
enum StudyTaskKind { review, learn, activeRecall, miniTest }

class StudyUnit {
  const StudyUnit({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    this.mastery = 0,
    this.lastStudiedAt,
    this.dueAt,
    this.isCompleted = false,
    this.estimatedMinutes = 12,
  });

  final String id;
  final String subjectId;
  final String title;
  final int order;
  final double mastery;
  final DateTime? lastStudiedAt;
  final DateTime? dueAt;
  final bool isCompleted;
  final int estimatedMinutes;
}

class StudyTask {
  const StudyTask({
    required this.kind,
    required this.title,
    required this.minutes,
    this.unitId,
    this.subjectId,
    this.reason,
  });

  final StudyTaskKind kind;
  final String title;
  final int minutes;
  final String? unitId;
  final String? subjectId;
  final String? reason;
}

class StudyPlan {
  const StudyPlan({
    required this.tasks,
    required this.totalMinutes,
    required this.headline,
    required this.explanation,
  });

  final List<StudyTask> tasks;
  final int totalMinutes;
  final String headline;
  final String explanation;

  bool get isEmpty => tasks.isEmpty;
}

/// Builds a short, adaptive daily session without asking the learner to choose
/// a subject or chapter. All date comparisons are local-device comparisons.
class StudyPlanner {
  const StudyPlanner();

  StudyPlan build({
    required List<StudyUnit> units,
    required DateTime now,
    int dailyGoalMinutes = 25,
    int dueReviewCount = 0,
    int dueReviewMinutes = 0,
  }) {
    final goal = dailyGoalMinutes.clamp(10, 300).toInt();
    final tasks = <StudyTask>[];
    var remaining = goal;

    if (goal > 50) {
      final unfinished = units.where((unit) => !unit.isCompleted).toList()
        ..sort((a, b) {
          final priority = _priority(b, now).compareTo(_priority(a, now));
          return priority != 0 ? priority : a.order.compareTo(b.order);
        });
      if (unfinished.isEmpty && dueReviewCount == 0) {
        return const StudyPlan(
          tasks: [],
          totalMinutes: 0,
          headline: 'Your study path is ready',
          explanation: 'Import a verified Grade 9 study pack or add recall cards to begin.',
        );
      }
      final primary = unfinished.isEmpty ? null : unfinished.first;
      final secondary = unfinished.length > 1 ? unfinished[1] : primary;
      final blocks = <StudyTask>[];
      void addBlock(StudyTaskKind kind, String title, StudyUnit? unit, String reason) {
        final minutes = math.min(50, remaining).toInt();
        if (minutes <= 0) return;
        blocks.add(StudyTask(
          kind: kind,
          title: title,
          minutes: minutes,
          unitId: unit?.id,
          subjectId: unit?.subjectId,
          reason: reason,
        ));
        remaining -= minutes;
      }

      if (dueReviewCount > 0) {
        addBlock(StudyTaskKind.review, 'Spaced recall and memory review', null,
            '$dueReviewCount items are due for spaced review');
      } else {
        addBlock(StudyTaskKind.learn, primary?.title ?? 'Core lesson', primary,
            'Start with the highest-priority unfinished topic');
      }
      addBlock(StudyTaskKind.learn, secondary?.title ?? primary?.title ?? 'Guided examples',
          secondary ?? primary, 'Build understanding with worked examples');
      addBlock(StudyTaskKind.activeRecall, 'Closed-book active recall', primary,
          'Explain the idea without looking at the source');
      addBlock(StudyTaskKind.learn, 'Independent practice', secondary ?? primary,
          'Practise the skill without step-by-step help');
      addBlock(StudyTaskKind.activeRecall, 'Interleaved review and teach-back', secondary ?? primary,
          'Retrieve an earlier idea and connect it to today’s topic');
      addBlock(StudyTaskKind.miniTest, 'Daily mastery check', secondary ?? primary,
          'Check understanding and identify what needs another pass');

      return StudyPlan(
        tasks: List.unmodifiable(blocks),
        totalMinutes: goal - remaining,
        headline: 'Your six-block study day is ready',
        explanation: 'Six focused blocks are planned. Breaks are separate and never count toward active study time.',
      );
    }

    if (dueReviewCount > 0 && remaining >= 3) {
      final minutes = math.min(
        remaining,
        math.max(3, dueReviewMinutes > 0 ? dueReviewMinutes : dueReviewCount * 2),
      ).toInt();
      tasks.add(StudyTask(
        kind: StudyTaskKind.review,
        title: 'Recall previous lessons',
        minutes: minutes,
        reason: '$dueReviewCount items are due for spaced review',
      ));
      remaining -= minutes;
    }

    final dueUnits = units.where((unit) =>
        !unit.isCompleted &&
        unit.dueAt != null &&
        !unit.dueAt!.isAfter(now)).toList()
      ..sort((a, b) {
        final overdueA = now.difference(a.dueAt!).inHours;
        final overdueB = now.difference(b.dueAt!).inHours;
        final masteryOrder = a.mastery.compareTo(b.mastery);
        return masteryOrder != 0 ? masteryOrder : overdueB.compareTo(overdueA);
      });

    final unfinished = units.where((unit) => !unit.isCompleted).toList();
    unfinished.sort((a, b) {
      final scoreA = _priority(a, now);
      final scoreB = _priority(b, now);
      final priorityOrder = scoreB.compareTo(scoreA);
      return priorityOrder != 0 ? priorityOrder : a.order.compareTo(b.order);
    });

    final chosen = dueUnits.isNotEmpty
        ? dueUnits.first
        : (unfinished.isNotEmpty ? unfinished.first : null);

    if (chosen != null && remaining >= 8) {
      final lessonMinutes =
          math.min(remaining, chosen.estimatedMinutes.clamp(8, 25)).toInt();
      tasks.add(StudyTask(
        kind: StudyTaskKind.learn,
        title: chosen.title,
        minutes: lessonMinutes,
        unitId: chosen.id,
        subjectId: chosen.subjectId,
        reason: dueUnits.isNotEmpty
            ? 'This lesson is due for another pass'
            : chosen.lastStudiedAt == null
                ? 'New lesson in your learning sequence'
                : 'Selected from your lowest-mastery / next-in-sequence topics',
      ));
      remaining -= lessonMinutes;

      if (remaining >= 4) {
        final recallMinutes = math.min(remaining, 5).toInt();
        tasks.add(StudyTask(
          kind: StudyTaskKind.activeRecall,
          title: 'Close the book and explain it',
          minutes: recallMinutes,
          unitId: chosen.id,
          subjectId: chosen.subjectId,
          reason: 'Check understanding without looking at the lesson',
        ));
        remaining -= recallMinutes;
      }
      if (remaining >= 3) {
        tasks.add(StudyTask(
          kind: StudyTaskKind.miniTest,
          title: 'Quick knowledge check',
          minutes: remaining,
          unitId: chosen.id,
          subjectId: chosen.subjectId,
          reason: 'Use your answers to adjust the next session',
        ));
        remaining = 0;
      }
    }

    if (tasks.isEmpty) {
      return const StudyPlan(
        tasks: [],
        totalMinutes: 0,
        headline: 'Your study path is ready',
        explanation:
            'Import or sync a verified Grade 9 study pack once. After that, the tutor chooses each daily lesson and review automatically.',
      );
    }

    final reviewOnly = chosen == null;
    return StudyPlan(
      tasks: List.unmodifiable(tasks),
      totalMinutes: goal - remaining,
      headline: reviewOnly ? 'Today’s memory workout' : 'Your next lesson is ready',
      explanation: 'Picked automatically from due reviews, your progress and the next unfinished lesson.',
    );
  }

  double _priority(StudyUnit unit, DateTime now) {
    if (unit.isCompleted) return -1;
    var score = ((1 - unit.mastery.clamp(0, 1)) * 100).toDouble();
    if (unit.lastStudiedAt == null) score += 30.0;
    if (unit.dueAt != null && !unit.dueAt!.isAfter(now)) {
      score += (80 + now.difference(unit.dueAt!).inHours.clamp(0, 720) / 24).toDouble();
    }
    if (unit.lastStudiedAt != null) {
      score += (now.difference(unit.lastStudiedAt!).inDays.clamp(0, 30) * 1.5).toDouble();
    }
    return score - unit.order * 0.001;
  }
}
