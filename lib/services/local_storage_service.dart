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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lessons(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            language TEXT,
            difficulty TEXT,
            contentSteps TEXT,
            isCompleted INTEGER
          )
        ''');
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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
