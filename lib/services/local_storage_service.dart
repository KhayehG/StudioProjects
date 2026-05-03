import 'dart:convert';

import 'package:path/path.dart' as path_lib;
import 'package:sqflite/sqflite.dart';

import '../models/lesson.dart';

class LocalStorageService {
  LocalStorageService._internal();

  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String fullPath = path_lib.join(dbPath, 'linguaflow.db');

    return openDatabase(
      fullPath,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE lessons(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            language TEXT,
            difficulty TEXT,
            contentSteps TEXT,
            isCompleted INTEGER,
            `order` INTEGER NOT NULL DEFAULT 1,
            xpReward INTEGER NOT NULL DEFAULT 10,
            quizXpReward INTEGER NOT NULL DEFAULT 20
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE lessons ADD COLUMN `order` INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE lessons ADD COLUMN xpReward INTEGER NOT NULL DEFAULT 10',
          );
          await db.execute(
            'ALTER TABLE lessons ADD COLUMN quizXpReward INTEGER NOT NULL DEFAULT 20',
          );
        }
      },
    );
  }

  Future<void> insertLesson(Lesson lesson) async {
    final Database db = await database;
    await db.insert(
      'lessons',
      <String, dynamic>{
        'id': lesson.id,
        'title': lesson.title,
        'description': lesson.description,
        'language': lesson.language,
        'difficulty': lesson.difficulty,
        'contentSteps': jsonEncode(lesson.contentSteps),
        'isCompleted': lesson.isCompleted ? 1 : 0,
        'order': lesson.order,
        'xpReward': lesson.xpReward,
        'quizXpReward': lesson.quizXpReward,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Lesson>> getAllLessons() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lessons');

    return maps.map((Map<String, dynamic> map) {
      return Lesson(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        language: map['language'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? '',
        contentSteps: List<String>.from(
          jsonDecode(map['contentSteps'] as String? ?? '[]') as List<dynamic>,
        ),
        order: (map['order'] as int?) ?? 1,
        xpReward: (map['xpReward'] as int?) ?? 10,
        quizXpReward: (map['quizXpReward'] as int?) ?? 20,
        isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<Lesson?> getLessonById(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: <dynamic>[id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final Map<String, dynamic> map = maps.first;
    return Lesson(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      language: map['language'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? '',
      contentSteps: List<String>.from(
        jsonDecode(map['contentSteps'] as String? ?? '[]') as List<dynamic>,
      ),
      order: (map['order'] as int?) ?? 1,
      xpReward: (map['xpReward'] as int?) ?? 10,
      quizXpReward: (map['quizXpReward'] as int?) ?? 20,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }

  Future<void> updateCompletion(String id, bool done) async {
    final Database db = await database;
    await db.update(
      'lessons',
      <String, dynamic>{'isCompleted': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }

  Future<void> clearAndInsertAll(List<Lesson> lessons) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete('lessons');
      for (final Lesson lesson in lessons) {
        await txn.insert(
          'lessons',
          <String, dynamic>{
            'id': lesson.id,
            'title': lesson.title,
            'description': lesson.description,
            'language': lesson.language,
            'difficulty': lesson.difficulty,
            'contentSteps': jsonEncode(lesson.contentSteps),
            'isCompleted': lesson.isCompleted ? 1 : 0,
            'order': lesson.order,
            'xpReward': lesson.xpReward,
            'quizXpReward': lesson.quizXpReward,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
