import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/constants/app_constants.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../models/review_log.dart';
import '../models/user_profile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI on desktop platforms (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = 'langcurve.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = join(docsDir.path, 'langcurve.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Topics Table
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Vocabularies Table
    await db.execute('''
      CREATE TABLE vocabularies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        definition TEXT DEFAULT '',
        part_of_speech TEXT DEFAULT '',
        phonetic_uk TEXT,
        audio_url_uk TEXT,
        phonetic_us TEXT,
        audio_url_us TEXT,
        user_example TEXT,
        easiness REAL DEFAULT 2.5,
        interval INTEGER DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        due_date TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        wrong_count INTEGER DEFAULT 0,
        cefr_level TEXT,
        synonyms TEXT,
        antonyms TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE,
        UNIQUE(topic_id, word)
      )
    ''');

    // 3. ReviewLog Table
    await db.execute('''
      CREATE TABLE review_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        quality INTEGER NOT NULL,
        easiness REAL NOT NULL,
        interval INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. User Profile Table (XP, Streak)
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        xp INTEGER DEFAULT 0,
        streak_days INTEGER DEFAULT 1,
        last_active TEXT
      )
    ''');

    // Seed User Profile
    await db.insert('user_profile', {
      'xp': 0,
      'streak_days': 1,
      'last_active': DateTime.now().toIso8601String(),
    });

    // Seed Default Topics
    for (final topic in AppConstants.defaultTopics) {
      await db.insert('topics', {
        'name': topic['name'],
        'description': topic['description'],
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // -------------------------------------------------------------
  // TOPIC OPERATIONS
  // -------------------------------------------------------------
  Future<List<Topic>> getTopics() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.*, COUNT(v.id) AS word_count
      FROM topics t
      LEFT JOIN vocabularies v ON t.id = v.topic_id
      GROUP BY t.id
      ORDER BY t.id ASC
    ''');
    return result.map((row) => Topic.fromMap(row)).toList();
  }

  Future<Topic> createTopic(String name, String? description) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('topics', {
      'name': name.trim(),
      'description': description?.trim(),
      'created_at': now,
    });
    return Topic(id: id, name: name.trim(), description: description?.trim());
  }

  Future<void> updateTopic(int id, String name, String? description) async {
    final db = await database;
    await db.update(
      'topics',
      {
        'name': name.trim(),
        'description': description?.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTopic(int id) async {
    final db = await database;
    await db.delete('vocabularies', where: 'topic_id = ?', whereArgs: [id]);
    await db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------
  // VOCABULARY OPERATIONS
  // -------------------------------------------------------------
  Future<List<Vocabulary>> getVocabularies({int? topicId}) async {
    final db = await database;
    List<Map<String, dynamic>> result;
    if (topicId != null) {
      result = await db.rawQuery('''
        SELECT v.*, t.name AS topic_name
        FROM vocabularies v
        JOIN topics t ON v.topic_id = t.id
        WHERE v.topic_id = ?
        ORDER BY v.id DESC
      ''', [topicId]);
    } else {
      result = await db.rawQuery('''
        SELECT v.*, t.name AS topic_name
        FROM vocabularies v
        JOIN topics t ON v.topic_id = t.id
        ORDER BY v.id DESC
      ''');
    }
    return result.map((row) => Vocabulary.fromMap(row)).toList();
  }

  Future<List<Vocabulary>> getDueVocabularies({int? topicId}) async {
    final vocabs = await getVocabularies(topicId: topicId);
    final now = DateTime.now();
    return vocabs.where((v) => v.dueDate.isBefore(now)).toList();
  }

  Future<Vocabulary> upsertVocabulary({
    required int topicId,
    required String word,
    String? definition,
    String? partOfSpeech,
    String? phoneticUk,
    String? audioUrlUk,
    String? phoneticUs,
    String? audioUrlUs,
    String? userExample,
    String? cefrLevel,
    String? synonyms,
    String? antonyms,
  }) async {
    final db = await database;
    final cleanWord = word.trim().toLowerCase();

    // Check if exists
    final existing = await db.query(
      'vocabularies',
      where: 'topic_id = ? AND LOWER(word) = ?',
      whereArgs: [topicId, cleanWord],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'vocabularies',
        {
          if (definition != null) 'definition': definition,
          if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
          if (phoneticUk != null) 'phonetic_uk': phoneticUk,
          if (audioUrlUk != null) 'audio_url_uk': audioUrlUk,
          if (phoneticUs != null) 'phonetic_us': phoneticUs,
          if (audioUrlUs != null) 'audio_url_us': audioUrlUs,
          if (userExample != null) 'user_example': userExample,
          if (cefrLevel != null) 'cefr_level': cefrLevel,
          if (synonyms != null) 'synonyms': synonyms,
          if (antonyms != null) 'antonyms': antonyms,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final updated = await db.query('vocabularies', where: 'id = ?', whereArgs: [id]);
      return Vocabulary.fromMap(updated.first);
    } else {
      final now = DateTime.now().toIso8601String();
      final id = await db.insert('vocabularies', {
        'topic_id': topicId,
        'word': cleanWord,
        'definition': definition ?? '',
        'part_of_speech': partOfSpeech ?? '',
        'phonetic_uk': phoneticUk,
        'audio_url_uk': audioUrlUk,
        'phonetic_us': phoneticUs,
        'audio_url_us': audioUrlUs,
        'user_example': userExample,
        'easiness': 2.5,
        'interval': 0,
        'repetitions': 0,
        'due_date': now,
        'correct_count': 0,
        'wrong_count': 0,
        'cefr_level': cefrLevel,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'created_at': now,
      });
      final inserted = await db.query('vocabularies', where: 'id = ?', whereArgs: [id]);
      return Vocabulary.fromMap(inserted.first);
    }
  }

  Future<void> updateExample(int id, String example) async {
    final db = await database;
    await db.update(
      'vocabularies',
      {'user_example': example.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSrsProgress(Vocabulary vocab) async {
    final db = await database;
    await db.update(
      'vocabularies',
      {
        'easiness': vocab.easiness,
        'interval': vocab.interval,
        'repetitions': vocab.repetitions,
        'due_date': vocab.dueDate.toIso8601String(),
        'correct_count': vocab.correctCount,
        'wrong_count': vocab.wrongCount,
      },
      where: 'id = ?',
      whereArgs: [vocab.id],
    );
  }

  Future<void> deleteVocabulary(int id) async {
    final db = await database;
    await db.delete('vocabularies', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------
  // REVIEW LOGS & USER STATS
  // -------------------------------------------------------------
  Future<void> addReviewLog(ReviewLog log) async {
    final db = await database;
    await db.insert('review_logs', log.toMap());
  }

  Future<List<ReviewLog>> getReviewLogs() async {
    final db = await database;
    final results = await db.query('review_logs', orderBy: 'created_at ASC');
    return results.map((row) => ReviewLog.fromMap(row)).toList();
  }

  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final results = await db.query('user_profile', limit: 1);
    if (results.isEmpty) {
      return UserProfile();
    }
    final row = results.first;
    return UserProfile(
      xp: (row['xp'] ?? 0) as int,
      streakDays: (row['streak_days'] ?? 1) as int,
    );
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final db = await database;
    await db.rawUpdate('UPDATE user_profile SET xp = xp + ?', [amount]);
  }

  // Total stats for dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final totalWordsRes = await db.rawQuery('SELECT COUNT(*) AS total FROM vocabularies');
    final totalExamplesRes = await db.rawQuery('SELECT COUNT(*) AS total FROM vocabularies WHERE user_example IS NOT NULL AND user_example != ""');
    final profile = await getUserProfile();
    final recentWordsRes = await db.query(
      'vocabularies',
      columns: ['word'],
      orderBy: 'id DESC',
      limit: 3,
    );

    final recentWords = recentWordsRes.map((r) => r['word'] as String).toList();

    return {
      'totalXp': profile.xp,
      'totalWords': (totalWordsRes.first['total'] ?? 0) as int,
      'totalExamples': (totalExamplesRes.first['total'] ?? 0) as int,
      'recentWords': recentWords,
      'levelTitle': profile.levelTitle,
    };
  }

  // -------------------------------------------------------------
  // BACKUP & RESTORE DATA
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final topics = await db.query('topics');
    final vocabularies = await db.query('vocabularies');
    final reviewLogs = await db.query('review_logs');
    final userProfile = await db.query('user_profile');

    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'user_profile': userProfile.isNotEmpty ? userProfile.first : {},
      'topics': topics,
      'vocabularies': vocabularies,
      'review_logs': reviewLogs,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing
      await txn.delete('review_logs');
      await txn.delete('vocabularies');
      await txn.delete('topics');
      await txn.delete('user_profile');

      // Restore User Profile
      if (data['user_profile'] is Map) {
        final profile = data['user_profile'] as Map<String, dynamic>;
        await txn.insert('user_profile', {
          'xp': profile['xp'] ?? 0,
          'streak_days': profile['streak_days'] ?? 1,
          'last_active': DateTime.now().toIso8601String(),
        });
      }

      // Restore Topics
      final topicIdMap = <int, int>{};
      if (data['topics'] is List) {
        for (final t in data['topics']) {
          final oldId = t['id'] as int;
          final newId = await txn.insert('topics', {
            'name': t['name'],
            'description': t['description'],
            'created_at': t['created_at'] ?? DateTime.now().toIso8601String(),
          });
          topicIdMap[oldId] = newId;
        }
      }

      // Restore Vocabularies
      if (data['vocabularies'] is List) {
        for (final v in data['vocabularies']) {
          final oldTopicId = v['topic_id'] as int;
          final newTopicId = topicIdMap[oldTopicId] ?? oldTopicId;
          await txn.insert('vocabularies', {
            'topic_id': newTopicId,
            'word': v['word'],
            'definition': v['definition'] ?? '',
            'part_of_speech': v['part_of_speech'] ?? '',
            'phonetic_uk': v['phonetic_uk'],
            'audio_url_uk': v['audio_url_uk'],
            'phonetic_us': v['phonetic_us'],
            'audio_url_us': v['audio_url_us'],
            'user_example': v['user_example'],
            'easiness': v['easiness'] ?? 2.5,
            'interval': v['interval'] ?? 0,
            'repetitions': v['repetitions'] ?? 0,
            'due_date': v['due_date'] ?? DateTime.now().toIso8601String(),
            'correct_count': v['correct_count'] ?? 0,
            'wrong_count': v['wrong_count'] ?? 0,
            'cefr_level': v['cefr_level'],
            'synonyms': v['synonyms'],
            'antonyms': v['antonyms'],
            'created_at': v['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // Restore Review Logs
      if (data['review_logs'] is List) {
        for (final r in data['review_logs']) {
          await txn.insert('review_logs', {
            'word': r['word'],
            'quality': r['quality'] ?? 5,
            'easiness': r['easiness'] ?? 2.5,
            'interval': r['interval'] ?? 1,
            'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }
}
