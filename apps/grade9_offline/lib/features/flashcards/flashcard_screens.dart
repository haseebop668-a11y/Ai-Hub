import 'package:flutter/material.dart';

import '../../core/sm2.dart';
import '../../data/local_database.dart';

class SubjectWorkspacePage extends StatefulWidget {
  const SubjectWorkspacePage({
    required this.subjectId,
    required this.subjectTitle,
    super.key,
  });

  final String subjectId;
  final String subjectTitle;

  @override
  State<SubjectWorkspacePage> createState() => _SubjectWorkspacePageState();
}

class _SubjectWorkspacePageState extends State<SubjectWorkspacePage> {
  late Future<List<Map<String, Object?>>> _cards;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _cards = LocalDatabase.instance.flashcardsForSubject(widget.subjectId);
  }

  Future<void> _createCard() async {
    final formKey = GlobalKey<FormState>();
    final chapter = TextEditingController();
    final question = TextEditingController();
    final answer = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a recall card'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: chapter,
                  decoration: const InputDecoration(
                    labelText: 'Chapter or topic',
                    hintText: 'e.g. Introduction',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: question,
                  decoration: const InputDecoration(labelText: 'Question / prompt'),
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter a question' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: answer,
                  decoration: const InputDecoration(labelText: 'Answer'),
                  minLines: 2,
                  maxLines: 5,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter an answer' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save card'),
          ),
        ],
      ),
    );

    if (created == true) {
      try {
        await LocalDatabase.instance.addFlashcard(
          subjectId: widget.subjectId,
          chapter: chapter.text,
          prompt: question.text,
          answer: answer.text,
        );
        if (!mounted) return;
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recall card saved on this device.')),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save card: $error')),
        );
      }
    }
    chapter.dispose();
    question.dispose();
    answer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCard,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New recall card'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _cards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load cards: ${snapshot.error}'));
          }
          final cards = snapshot.data ?? const [];
          if (cards.isEmpty) {
            return _EmptySubject(onCreate: _createCard);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            children: [
              Text(
                '${cards.length} saved recall ${cards.length == 1 ? 'card' : 'cards'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...cards.map((card) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF1D8),
                        child: Icon(Icons.style_rounded, color: Color(0xFFD97706)),
                      ),
                      title: Text(card['prompt']! as String,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text((card['chapter'] as String).isEmpty
                          ? 'No chapter label'
                          : card['chapter']! as String),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showAnswer(context, card),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showAnswer(BuildContext context, Map<String, Object?> card) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QUESTION', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(card['prompt']! as String,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Text('ANSWER', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(card['answer']! as String,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySubject extends StatelessWidget {
  const _EmptySubject({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, size: 52, color: Color(0xFFD97706)),
            const SizedBox(height: 16),
            Text('Start building your memory bank',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Create question-and-answer cards from your textbook. '
              'They stay on your device and can be reviewed offline.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create first card'),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardReviewPage extends StatefulWidget {
  const FlashcardReviewPage({super.key});

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  late Future<List<Map<String, Object?>>> _queue;
  int _index = 0;
  bool _showAnswer = false;
  bool _saving = false;
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    _queue = LocalDatabase.instance.dueFlashcards();
  }

  Future<void> _rate(Map<String, Object?> card, int difficulty) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final schedule = const Sm2Scheduler().review(
        difficulty: difficulty,
        previousRepetitions: card['repetitions']! as int,
        previousIntervalDays: card['interval_days']! as int,
        previousEaseFactor: (card['ease_factor']! as num).toDouble(),
        reviewedAt: now,
      );
      await LocalDatabase.instance.saveReview(
        cardId: card['id']! as int,
        difficulty: difficulty,
        intervalDays: schedule.intervalDays,
        repetitions: schedule.repetitions,
        easeFactor: schedule.easeFactor,
        dueAt: schedule.dueAt,
        reviewedAt: now,
      );
      if (!mounted) return;
      setState(() {
        _index++;
        _completed++;
        _showAnswer = false;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review could not be saved: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory review')),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load review queue: ${snapshot.error}'));
          }
          final cards = snapshot.data ?? const [];
          if (cards.isEmpty || _index >= cards.length) {
            return _ReviewComplete(
              completed: _completed,
              onClose: () => Navigator.pop(context),
            );
          }
          final card = cards[_index];
          final progress = (_index + 1) / cards.length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CARD ${_index + 1} OF ${cards.length}',
                      style: Theme.of(context).textTheme.labelMedium),
                  Text('$_completed completed',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress, minHeight: 7),
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(minHeight: 230),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFECE7DD)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text((card['chapter'] as String).isEmpty
                        ? 'RECALL'
                        : (card['chapter']! as String).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 18),
                    Text(card['prompt']! as String,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (_showAnswer) ...[
                      const Divider(height: 32),
                      Text(card['answer']! as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_showAnswer)
                FilledButton(
                  onPressed: () => setState(() => _showAnswer = true),
                  child: const Text('Reveal answer'),
                )
              else ...[
                const Text('How well did you remember?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final option in const [
                  (1, 'Forgot', 'Again soon'),
                  (2, 'Difficult', 'Needs more practice'),
                  (3, 'Almost', 'Some effort'),
                  (4, 'Good', 'Remembered well'),
                  (5, 'Easy', 'Instant recall'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _rate(card, option.$1),
                      child: Row(
                        children: [
                          Expanded(child: Text(option.$2)),
                          Text(option.$3,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                if (_saving)
                  const Center(child: CircularProgressIndicator()),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({required this.completed, required this.onClose});

  final int completed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 64, color: Color(0xFFD97706)),
            const SizedBox(height: 16),
            Text(completed == 0 ? 'All caught up!' : 'Review complete!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              completed == 0
                  ? 'No cards are due right now. Add cards from a subject to start practising.'
                  : 'You reviewed $completed ${completed == 1 ? 'card' : 'cards'}. Your next intervals have been saved offline.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onClose, child: const Text('Back to study desk')),
          ],
        ),
      ),
    );
  }
}
