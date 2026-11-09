import 'package:flutter/material.dart';

import '../../core/study_planner.dart';
import '../../data/local_database.dart';
import '../flashcards/flashcard_screens.dart';

class TodayTutorPage extends StatefulWidget {
  const TodayTutorPage({super.key});

  @override
  State<TodayTutorPage> createState() => _TodayTutorPageState();
}

class _TodayTutorPageState extends State<TodayTutorPage> {
  late Future<_TutorSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_TutorSnapshot> _load() async {
    final db = LocalDatabase.instance;
    final results = await Future.wait([
      db.learningUnits(),
      db.dueFlashcards(),
      db.learnerProfile(),
    ]);
    final units = (results[0] as List<Map<String, Object?>>).map((row) {
      final last = row['last_studied_at'] as int?;
      final due = row['due_at'] as int?;
      return StudyUnit(
        id: row['id']! as String,
        subjectId: row['subject_id']! as String,
        title: row['title']! as String,
        order: row['sequence_order']! as int,
        mastery: (row['mastery'] as num).toDouble(),
        lastStudiedAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
        dueAt: due == null ? null : DateTime.fromMillisecondsSinceEpoch(due),
        isCompleted: row['is_completed'] == 1,
        estimatedMinutes: row['estimated_minutes']! as int,
      );
    }).toList();
    final dueCards = results[1] as List<Map<String, Object?>>;
    final profile = results[2] as Map<String, Object?>;
    final goal = profile['daily_goal_minutes']! as int;
    return _TutorSnapshot(
      plan: const StudyPlanner().build(
        units: units,
        now: DateTime.now(),
        dailyGoalMinutes: goal,
        dueReviewCount: dueCards.length,
        dueReviewMinutes: dueCards.length * 2,
      ),
      dueCards: dueCards.length,
      unitCount: units.length,
      completedUnits: units.where((unit) => unit.isCompleted).length,
    );
  }

  Future<void> _refresh() async {
    setState(() => _snapshot = _load());
    await _snapshot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's study session")),
      body: FutureBuilder<_TutorSnapshot>(
        future: _snapshot,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Center(child: Text('Could not prepare your session: ${state.error}'));
          }
          final data = state.data!;
          final plan = data.plan;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D8),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR PERSONAL TUTOR',
                          style: TextStyle(fontSize: 11, letterSpacing: 1.4,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text(plan.headline,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(plan.explanation, style: const TextStyle(height: 1.45)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(plan.isEmpty ? 'No lesson content indexed' :
                              '${plan.totalMinutes} minute session'),
                          const Spacer(),
                          Text('${data.completedUnits}/${data.unitCount} lessons mastered'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (plan.isEmpty) ...[
                  _EmptyTutorState(
                    hasCards: data.dueCards > 0,
                    onReview: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FlashcardReviewPage(),
                      ),
                    ).then((_) => _refresh()),
                  ),
                ] else ...[
                  Text('THE TUTOR PICKED THIS FOR YOU',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFD97706), letterSpacing: 1.1,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...plan.tasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    final icon = switch (task.kind) {
                      StudyTaskKind.review => Icons.history_rounded,
                      StudyTaskKind.learn => Icons.auto_stories_rounded,
                      StudyTaskKind.activeRecall => Icons.psychology_alt_rounded,
                      StudyTaskKind.miniTest => Icons.quiz_rounded,
                    };
                    final label = switch (task.kind) {
                      StudyTaskKind.review => 'SPACED REVIEW',
                      StudyTaskKind.learn => 'NEW / WEAK LESSON',
                      StudyTaskKind.activeRecall => 'ACTIVE RECALL',
                      StudyTaskKind.miniTest => 'QUICK TEST',
                    };
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF1D8),
                          child: Icon(icon, color: const Color(0xFFD97706)),
                        ),
                        title: Text(task.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('$label · ${task.minutes} min\n${task.reason ?? ''}'),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.play_circle_outline_rounded),
                        onTap: () {
                          if (task.kind == StudyTaskKind.review) {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => const FlashcardReviewPage(),
                            )).then((_) => _refresh());
                          } else if (task.unitId != null) {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => StudyLessonPage(
                                unitId: task.unitId!,
                                startInRecall: task.kind != StudyTaskKind.learn,
                              ),
                            )).then((_) => _refresh());
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text(
                    'Your next session changes according to your recall results. '
                    'You do not need to pick the next chapter yourself.',
                    style: TextStyle(color: Color(0xFF667085), height: 1.4),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TutorSnapshot {
  const _TutorSnapshot({
    required this.plan,
    required this.dueCards,
    required this.unitCount,
    required this.completedUnits,
  });

  final StudyPlan plan;
  final int dueCards;
  final int unitCount;
  final int completedUnits;
}

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState({required this.hasCards, required this.onReview});

  final bool hasCards;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.library_books_rounded, size: 34,
                color: Color(0xFFD97706)),
            const SizedBox(height: 12),
            Text('Your tutor needs a textbook study pack',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'The automatic planner is connected, but there are no verified '
              'chapter lessons indexed on this device yet. The PDF import and '
              'official curriculum sync pipeline is the next build step. '
              'We will not invent textbook lessons or silently use an outdated edition.',
              style: TextStyle(height: 1.45),
            ),
            if (hasCards) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.psychology_alt_rounded),
                label: const Text('Review saved recall cards'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StudyLessonPage extends StatefulWidget {
  const StudyLessonPage({
    required this.unitId,
    this.startInRecall = false,
    super.key,
  });

  final String unitId;
  final bool startInRecall;

  @override
  State<StudyLessonPage> createState() => _StudyLessonPageState();
}

class _StudyLessonPageState extends State<StudyLessonPage> {
  final _answer = TextEditingController();
  late Future<Map<String, Object?>?> _unit;
  bool _recalling = false;
  bool _checked = false;
  double? _score;

  @override
  void initState() {
    super.initState();
    _recalling = widget.startInRecall;
    _unit = LocalDatabase.instance.learningUnit(widget.unitId);
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Set<String> _keywords(String text) {
    const stopWords = {
      'this', 'that', 'with', 'from', 'have', 'were', 'what', 'when',
      'where', 'which', 'their', 'there', 'then', 'than', 'into', 'about',
      'your', 'they', 'them', 'will', 'would', 'could', 'should', 'also',
      'the', 'and', 'for', 'are', 'was', 'you', 'but', 'not', 'can',
    };
    return RegExp(r'[a-zA-Z0-9]{3,}')
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0)!)
        .where((word) => !stopWords.contains(word))
        .toSet();
  }

  Future<void> _checkRecall(Map<String, Object?> unit) async {
    final source = _keywords(unit['body_text']! as String);
    final response = _keywords(_answer.text);
    final coverage = source.isEmpty ? 0.0 : response.intersection(source).length / source.length;
    final score = coverage.clamp(0.0, 1.0);
    final now = DateTime.now();
    await LocalDatabase.instance.recordLearningOutcome(
      unitId: widget.unitId,
      score: score,
      completedAt: now,
    );
    if (!mounted) return;
    setState(() {
      _score = score;
      _checked = true;
      _recalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn and recall')),
      body: FutureBuilder<Map<String, Object?>?>(
        future: _unit,
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = state.data;
          if (unit == null) {
            return const Center(child: Text('This lesson is no longer available.'));
          }
          final body = unit['body_text']! as String;
          final paragraphs = body.split(RegExp(r'\n\s*\n'))
              .where((part) => part.trim().isNotEmpty).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(unit['chapter_title']! as String,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFD97706))),
              const SizedBox(height: 8),
              Text(unit['title']! as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              if (!_recalling && !_checked) ...[
                const Text('Read this short lesson carefully. Then close the book and explain it.',
                    style: TextStyle(height: 1.45)),
                const SizedBox(height: 14),
                ...paragraphs.map((paragraph) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(paragraph, style: const TextStyle(fontSize: 16, height: 1.55)),
                )),
                if (unit['page_start'] != null)
                  Text('Textbook pages ${unit['page_start']}-${unit['page_end'] ?? unit['page_start']}',
                      style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _recalling = true),
                  child: const Text('I have read it — test my memory'),
                ),
              ] else if (_recalling) ...[
                const Text('Close the book. Explain the main idea in your own words.',
                    style: TextStyle(fontWeight: FontWeight.w700, height: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: _answer,
                  minLines: 5,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Write what you remember without looking…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _answer.text.trim().isEmpty ? null : () => _checkRecall(unit),
                  child: const Text('Check my recall'),
                ),
              ] else ...[
                const Icon(Icons.insights_rounded, size: 38,
                    color: Color(0xFF16845B)),
                const SizedBox(height: 10),
                Text('Keyword coverage: ${((_score ?? 0) * 100).round()}%',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'This is a simple offline word-coverage signal, not an AI judgement '
                  'of meaning. Compare your answer with the source below and correct anything missing.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text('SOURCE LESSON', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Finish session'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
