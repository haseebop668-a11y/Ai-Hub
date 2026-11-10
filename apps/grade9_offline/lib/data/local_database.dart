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
      version: 5,
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
        await _createAdaptiveTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAdaptiveTables(database);
        }
        if (oldVersion < 3) {
          await _createImportedBooksTable(database);
        }
        if (oldVersion < 4) {
          await _upgradeStudyDiscipline(database);
        }
        if (oldVersion < 5) {
          await _upgradeActiveStudyTotals(database);
        }
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

  Future<List<Map<String, Object?>>> subjects() async {
    final db = await database;
    return db.query('subjects', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> flashcardsForSubject(String subjectId) async {
    final db = await database;
    return db.query(
      'flashcards',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC, id DESC',
    );
  }

  Future<int> flashcardCount({String? subjectId}) async {
    final db = await database;
    final rows = await db.rawQuery(
      subjectId == null
          ? 'SELECT COUNT(*) AS total FROM flashcards'
          : 'SELECT COUNT(*) AS total FROM flashcards WHERE subject_id = ?',
      subjectId == null ? null : [subjectId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
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

  Future<void> _createImportedBooksTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS imported_books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        local_path TEXT NOT NULL UNIQUE,
        imported_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createAdaptiveTables(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS learning_sources(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        board TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        medium TEXT NOT NULL,
        local_path TEXT NOT NULL,
        source_url TEXT,
        content_hash TEXT NOT NULL,
        imported_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS learning_units(
        id TEXT PRIMARY KEY,
        source_id TEXT,
        subject_id TEXT NOT NULL,
        chapter_title TEXT NOT NULL,
        title TEXT NOT NULL,
        body_text TEXT NOT NULL,
        page_start INTEGER,
        page_end INTEGER,
        sequence_order INTEGER NOT NULL,
        mastery REAL NOT NULL DEFAULT 0,
        last_studied_at INTEGER,
        due_at INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        estimated_minutes INTEGER NOT NULL DEFAULT 12,
        FOREIGN KEY(source_id) REFERENCES learning_sources(id) ON DELETE SET NULL,
        FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS learning_attempts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id TEXT NOT NULL,
        mode TEXT NOT NULL,
        prompt TEXT NOT NULL,
        expected_answer TEXT,
        learner_answer TEXT,
        score REAL NOT NULL,
        feedback TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(unit_id) REFERENCES learning_units(id) ON DELETE CASCADE
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS learner_profile(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        board TEXT NOT NULL DEFAULT 'Punjab',
        academic_year TEXT NOT NULL DEFAULT '2026-27',
        medium TEXT NOT NULL DEFAULT 'English',
        daily_goal_minutes INTEGER NOT NULL DEFAULT 300,
        setup_completed INTEGER NOT NULL DEFAULT 0,
        schedule_mode TEXT NOT NULL DEFAULT 'fixed',
        weekly_rest_day INTEGER NOT NULL DEFAULT 7,
        study_start_hour INTEGER,
        study_start_minute INTEGER,
        break_minutes INTEGER NOT NULL DEFAULT 10,
        focus_mode_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await database.execute("""
      CREATE TABLE IF NOT EXISTS daily_study_totals(
        day_key TEXT PRIMARY KEY,
        active_seconds INTEGER NOT NULL DEFAULT 0,
        active_minutes INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    """);
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        planned_minutes INTEGER NOT NULL,
        completed_minutes INTEGER NOT NULL DEFAULT 0,
        outcome TEXT NOT NULL DEFAULT 'in_progress'
      )
    ''');
    await database.insert(
      'learner_profile',
      {'id': 1},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _upgradeActiveStudyTotals(DatabaseExecutor database) async {
    final columns = await database.rawQuery('PRAGMA table_info(daily_study_totals)');
    if (!columns.any((row) => row['name'] == 'active_seconds')) {
      await database.execute(
        'ALTER TABLE daily_study_totals ADD COLUMN active_seconds INTEGER NOT NULL DEFAULT 0',
      );
      await database.execute(
        'UPDATE daily_study_totals SET active_seconds = active_minutes * 60',
      );
    }
  }

  Future<void> _upgradeStudyDiscipline(DatabaseExecutor database) async {
    Future<void> addColumnIfMissing(String table, String column, String declaration) async {
      final columns = await database.rawQuery('PRAGMA table_info($table)');
      if (!columns.any((row) => row['name'] == column)) {
        await database.execute('ALTER TABLE $table ADD COLUMN $column $declaration');
      }
    }

    await addColumnIfMissing('learner_profile', 'schedule_mode', "TEXT NOT NULL DEFAULT 'fixed'");
    await addColumnIfMissing('learner_profile', 'weekly_rest_day', 'INTEGER NOT NULL DEFAULT 7');
    await addColumnIfMissing('learner_profile', 'study_start_hour', 'INTEGER');
    await addColumnIfMissing('learner_profile', 'study_start_minute', 'INTEGER');
    await addColumnIfMissing('learner_profile', 'break_minutes', 'INTEGER NOT NULL DEFAULT 10');
    await addColumnIfMissing('learner_profile', 'focus_mode_enabled', 'INTEGER NOT NULL DEFAULT 0');
    await database.execute("UPDATE learner_profile SET daily_goal_minutes = 300 WHERE daily_goal_minutes = 25 AND setup_completed = 0");
    await addColumnIfMissing('study_sessions', 'activity_type', "TEXT NOT NULL DEFAULT 'study'");
    await addColumnIfMissing('study_sessions', 'last_interaction_at', 'INTEGER');
    await addColumnIfMissing('study_sessions', 'paused_at', 'INTEGER');
    await database.execute("CREATE TABLE IF NOT EXISTS daily_study_totals(day_key TEXT PRIMARY KEY, active_minutes INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL)");
  }

  Future<List<Map<String, Object?>>> learningUnits() async {
    final db = await database;
    return db.query(
      'learning_units',
      orderBy: 'sequence_order ASC, id ASC',
    );
  }

  Future<Map<String, Object?>?> learningUnit(String id) async {
    final db = await database;
    final rows = await db.query(
      'learning_units',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveLearningUnit({
    required String id,
    required String subjectId,
    required String chapterTitle,
    required String title,
    required String bodyText,
    required int sequenceOrder,
    String? sourceId,
    int? pageStart,
    int? pageEnd,
    int estimatedMinutes = 12,
  }) async {
    if (id.trim().isEmpty || title.trim().isEmpty || bodyText.trim().isEmpty) {
      throw ArgumentError('A learning unit needs an id, title and source text.');
    }
    final db = await database;
    await db.insert('learning_units', {
      'id': id,
      'source_id': sourceId,
      'subject_id': subjectId,
      'chapter_title': chapterTitle,
      'title': title,
      'body_text': bodyText,
      'page_start': pageStart,
      'page_end': pageEnd,
      'sequence_order': sequenceOrder,
      'estimated_minutes': estimatedMinutes.clamp(5, 45),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordLearningOutcome({
    required String unitId,
    required double score,
    required DateTime completedAt,
  }) async {
    if (!score.isFinite || score < 0 || score > 1) {
      throw ArgumentError.value(score, 'score', 'Must be between 0 and 1.');
    }
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'learning_units',
        columns: ['mastery'],
        where: 'id = ?',
        whereArgs: [unitId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Learning unit does not exist.');
      final oldMastery = (rows.first['mastery'] as num).toDouble();
      final nextMastery = (oldMastery * 0.6 + score * 0.4).clamp(0.0, 1.0);
      final nextDueDays = score >= 0.85 ? 3 : score >= 0.6 ? 1 : 0;
      await txn.update(
        'learning_units',
        {
          'mastery': nextMastery,
          'last_studied_at': completedAt.millisecondsSinceEpoch,
          'due_at': completedAt.add(Duration(days: nextDueDays)).millisecondsSinceEpoch,
          'is_completed': nextMastery >= 0.9 ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [unitId],
      );
    });
  }

  Future<void> addActiveStudySeconds({
    required DateTime day,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    final db = await database;
    final key = _dayKey(day);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert(
      '''
      INSERT INTO daily_study_totals(day_key, active_seconds, active_minutes, updated_at)
      VALUES(?, ?, 0, ?)
      ON CONFLICT(day_key) DO UPDATE SET
        active_seconds = daily_study_totals.active_seconds + excluded.active_seconds,
        updated_at = excluded.updated_at
      ''',
      [key, seconds, now],
    );
    await db.rawUpdate(
      'UPDATE daily_study_totals SET active_minutes = active_seconds / 60 WHERE day_key = ?',
      [key],
    );
  }

  Future<int> activeStudySecondsForDay(DateTime day) async {
    final db = await database;
    final rows = await db.query(
      'daily_study_totals',
      columns: ['active_seconds'],
      where: 'day_key = ?',
      whereArgs: [_dayKey(day)],
      limit: 1,
    );
    return rows.isEmpty ? 0 : rows.first['active_seconds']! as int;
  }

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<Map<String, Object?>> learnerProfile() async {
    final db = await database;
    final rows = await db.query('learner_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) throw StateError('Learner profile is missing.');
    return rows.first;
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

  Future<List<Map<String, Object?>>> importedBooks() async {
    final db = await database;
    return db.query('imported_books', orderBy: 'imported_at DESC, id DESC');
  }

  Future<int> addImportedBook({
    required String title,
    required String localPath,
  }) async {
    final cleanTitle = title.trim();
    final cleanPath = localPath.trim();
    if (cleanTitle.isEmpty || cleanPath.isEmpty) {
      throw ArgumentError('A PDF needs a title and local file path.');
    }
    final db = await database;
    return db.insert(
      'imported_books',
      {
        'title': cleanTitle,
        'local_path': cleanPath,
        'imported_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeImportedBook(int id) async {
    final db = await database;
    await db.delete('imported_books', where: 'id = ?', whereArgs: [id]);
  }

}
