import 'package:flutter_test/flutter_test.dart';
import 'package:grade9_offline_learning/core/study_planner.dart';

void main() {
  const planner = StudyPlanner();
  final now = DateTime(2026, 11, 10, 9);

  test('selects the lowest mastery unfinished unit automatically', () {
    final plan = planner.build(
      now: now,
      dailyGoalMinutes: 25,
      units: [
        StudyUnit(id: 'a', subjectId: 'math', title: 'Algebra', order: 1,
            mastery: 0.9, lastStudiedAt: DateTime(2026, 11, 9)),
        StudyUnit(id: 'b', subjectId: 'physics', title: 'Motion', order: 2,
            mastery: 0.2, lastStudiedAt: DateTime(2026, 11, 8)),
      ],
    );

    expect(plan.isEmpty, isFalse);
    expect(plan.tasks.first.kind, StudyTaskKind.learn);
    expect(plan.tasks.first.unitId, 'b');
    expect(plan.tasks.any((task) => task.kind == StudyTaskKind.activeRecall), isTrue);
    expect(plan.tasks.any((task) => task.kind == StudyTaskKind.miniTest), isTrue);
  });

  test('overdue unit is prioritized over an untouched unit', () {
    final plan = planner.build(
      now: now,
      dailyGoalMinutes: 25,
      units: [
        StudyUnit(id: 'new', subjectId: 'math', title: 'New topic', order: 1),
        StudyUnit(id: 'due', subjectId: 'physics', title: 'Due topic', order: 2,
            mastery: 0.7, dueAt: DateTime(2026, 11, 8)),
      ],
    );

    expect(plan.tasks.first.unitId, 'due');
  });

  test('empty curriculum returns honest import state', () {
    final plan = planner.build(now: now, units: []);
    expect(plan.isEmpty, isTrue);
    expect(plan.explanation, contains('Import'));
  });

  test('completed units are never selected', () {
    final plan = planner.build(
      now: now,
      units: [
        StudyUnit(id: 'done', subjectId: 'math', title: 'Finished', order: 1,
            isCompleted: true, mastery: 1),
      ],
    );
    expect(plan.isEmpty, isTrue);
  });
  test('300-minute study day contains six active 50-minute blocks', () {
    final plan = planner.build(
      now: now,
      dailyGoalMinutes: 300,
      dueReviewCount: 12,
      units: [
        StudyUnit(id: 'a', subjectId: 'math', title: 'Algebra', order: 1, mastery: 0.3),
        StudyUnit(id: 'b', subjectId: 'physics', title: 'Motion', order: 2, mastery: 0.5),
      ],
    );

    expect(plan.totalMinutes, 300);
    expect(plan.tasks, hasLength(6));
    expect(plan.tasks.map((task) => task.minutes), everyElement(50));
    expect(plan.tasks.first.kind, StudyTaskKind.review);
    expect(plan.tasks.last.kind, StudyTaskKind.miniTest);
  });

}
