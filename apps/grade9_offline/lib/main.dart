import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.database;
  runApp(const GradeNineApp());
}

class GradeNineApp extends StatelessWidget {
  const GradeNineApp({super.key});

  static const cream = Color(0xFFFFFDF7);
  static const slate = Color(0xFF1F2937);
  static const amber = Color(0xFFD97706);
  static const emerald = Color(0xFF16845B);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: amber,
      brightness: Brightness.light,
      surface: cream,
    );
    return MaterialApp(
      title: 'Grade 9 Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: cream,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: slate,
          displayColor: slate,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE7DD)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: slate,
          centerTitle: false,
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const subjects = [
    ('Mathematics', 'math', Icons.functions_rounded),
    ('Physics', 'physics', Icons.bolt_rounded),
    ('Chemistry', 'chemistry', Icons.science_rounded),
    ('Biology', 'biology', Icons.biotech_rounded),
    ('Computer Science', 'computer', Icons.computer_rounded),
    ('English', 'english', Icons.menu_book_rounded),
    ('Urdu', 'urdu', Icons.translate_rounded),
  ];

  int _dueCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDueCount();
  }

  Future<void> _loadDueCount() async {
    try {
      final cards = await LocalDatabase.instance.dueFlashcards();
      if (!mounted) return;
      setState(() {
        _dueCount = cards.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR STUDY DESK',
                style: TextStyle(fontSize: 11, letterSpacing: 1.5)),
            Text('Grade 9', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh review count',
            onPressed: _loadDueCount,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDueCount,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Small steps. Strong memory.',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                      'Read a little, explain it in your own words, then recall it without looking.',
                      style: TextStyle(height: 1.45),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.offline_bolt_rounded, color: GradeNineApp.emerald),
                        SizedBox(width: 6),
                        Text('Your study progress stays on this device',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE4F3EA),
                    child: Icon(Icons.psychology_alt_rounded,
                        color: GradeNineApp.emerald),
                  ),
                  title: const Text('Memory review',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_loading
                      ? 'Checking your review queue…'
                      : '$_dueCount cards due for review'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showReviewInfo(context),
                ),
              ),
              const SizedBox(height: 22),
              const Text('YOUR SUBJECTS',
                  style: TextStyle(fontSize: 12, letterSpacing: 1.4,
                      fontWeight: FontWeight.w800, color: GradeNineApp.amber)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.48,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showSubjectInfo(context, subject.$1),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(subject.$3, size: 27, color: GradeNineApp.amber),
                            Text(subject.$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Curriculum content is kept separate from the app engine. '
                'Add verified textbook material before using chapter lessons.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Memory review'),
        content: const Text(
          'The local SM-2 review scheduler and SQLite storage are in place. '
          'Create and populate verified chapter cards in the next learning-content module.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSubjectInfo(BuildContext context, String subject) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'The subject workspace is ready for verified textbook chapters, '
              'lesson explanations, exercises and revision cards.',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
