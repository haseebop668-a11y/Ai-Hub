import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;
    final root = await getDatabasesPath();
    final db = await openDatabase(
      p.join(root, 'grade9_learning.db'),
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE subjects(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE flashcards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id TEXT NOT NULL,
            chapter TEXT NOT NULL,
            prompt TEXT NOT NULL,
            answer TEXT NOT NULL,
            repetitions INTEGER NOT NULL DEFAULT 0,
            interval_days INTEGER NOT NULL DEFAULT 0,
            ease_factor REAL NOT NULL DEFAULT 2.5,
            due_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE review_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id INTEGER NOT NULL,
            difficulty INTEGER NOT NULL CHECK(difficulty BETWEEN 1 AND 5),
            reviewed_at INTEGER NOT NULL,
            interval_days INTEGER NOT NULL,
            FOREIGN KEY(card_id) REFERENCES flashcards(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE study_progress(
            id TEXT PRIMARY KEY,
            completed_count INTEGER NOT NULL DEFAULT 0,
            xp INTEGER NOT NULL DEFAULT 0,
            streak_days INTEGER NOT NULL DEFAULT 0,
            last_study_day TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE imported_books(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            local_path TEXT NOT NULL UNIQUE,
            imported_at INTEGER NOT NULL
          )
        ''');
        final batch = database.batch();
        const subjects = [
          ['math', 'Mathematics', 1],
          ['physics', 'Physics', 2],
          ['chemistry', 'Chemistry', 3],
          ['biology', 'Biology', 4],
          ['computer', 'Computer Science', 5],
          ['english', 'English', 6],
          ['urdu', 'Urdu', 7],
        ];
        for (final subject in subjects) {
          batch.insert('subjects', {
            'id': subject[0],
            'title': subject[1],
            'sort_order': subject[2],
          });
        }
        await batch.commit(noResult: true);
      },
    );
    _database = db;
    return db;
  }

  Future<int> addFlashcard({
    required String subjectId,
    required String chapter,
    required String prompt,
    required String answer,
    DateTime? now,
  }) async {
    final cleanPrompt = prompt.trim();
    final cleanAnswer = answer.trim();
    if (cleanPrompt.isEmpty || cleanAnswer.isEmpty) {
      throw ArgumentError('Question and answer cannot be empty.');
    }
    final db = await database;
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return db.insert('flashcards', {
      'subject_id': subjectId,
      'chapter': chapter.trim(),
      'prompt': cleanPrompt,
      'answer': cleanAnswer,
      'due_at': timestamp,
      'created_at': timestamp,
    });
  }

  Future<List<Map<String, Object?>>> dueFlashcards({DateTime? now}) async {
    final db = await database;
    return db.query(
      'flashcards',
      where: 'due_at <= ?',
      whereArgs: [(now ?? DateTime.now()).millisecondsSinceEpoch],
      orderBy: 'due_at ASC, id ASC',
    );
  }

  Future<void> saveReview({
    required int cardId,
    required int difficulty,
    required int intervalDays,
    required int repetitions,
    required double easeFactor,
    required DateTime dueAt,
    required DateTime reviewedAt,
  }) async {
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError.value(difficulty, 'difficulty');
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'flashcards',
        {
          'interval_days': intervalDays,
          'repetitions': repetitions,
          'ease_factor': easeFactor,
          'due_at': dueAt.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [cardId],
      );
      await txn.insert('review_logs', {
        'card_id': cardId,
        'difficulty': difficulty,
        'reviewed_at': reviewedAt.millisecondsSinceEpoch,
        'interval_days': intervalDays,
      });
    });
  }
}
