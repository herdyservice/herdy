import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/date_utils.dart';
import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'ma_sorciere.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE periods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_date TEXT NOT NULL UNIQUE,
            end_date TEXT,
            flow TEXT,
            pain INTEGER,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            moods TEXT,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE symptoms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT NOT NULL,
            intensity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE intercourse (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            time TEXT,
            protected_sex INTEGER,
            condom INTEGER,
            contraception INTEGER,
            notes TEXT
          )
        ''');
      },
    );
  }

  // ---------- Règles ----------
  Future<List<PeriodEntry>> getPeriods() async {
    final db = await database;
    final rows = await db.query('periods', orderBy: 'start_date ASC');
    return rows.map(PeriodEntry.fromMap).toList();
  }

  Future<int> upsertPeriod(PeriodEntry e) async {
    final db = await database;
    if (e.id != null) {
      await db.update('periods', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
      return e.id!;
    }
    return db.insert('periods', e.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePeriod(int id) async {
    final db = await database;
    await db.delete('periods', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Humeurs ----------
  Future<List<MoodEntry>> getMoods() async {
    final db = await database;
    final rows = await db.query('moods', orderBy: 'date ASC');
    return rows.map(MoodEntry.fromMap).toList();
  }

  Future<void> saveMood(MoodEntry e) async {
    final db = await database;
    await db.delete('moods', where: 'date = ?', whereArgs: [iso(e.date)]);
    if (e.moods.isEmpty && e.note.trim().isEmpty) return;
    await db.insert('moods', e.toMap()..remove('id'));
  }

  // ---------- Symptômes ----------
  Future<List<SymptomEntry>> getSymptoms() async {
    final db = await database;
    final rows = await db.query('symptoms', orderBy: 'date ASC');
    return rows.map(SymptomEntry.fromMap).toList();
  }

  Future<void> saveSymptoms(DateTime date, List<SymptomEntry> list) async {
    final db = await database;
    final key = iso(date);
    await db.delete('symptoms', where: 'date = ?', whereArgs: [key]);
    for (final s in list) {
      await db.insert('symptoms', s.toMap()..remove('id'));
    }
  }

  // ---------- Rapports ----------
  Future<List<IntercourseEntry>> getIntercourse() async {
    final db = await database;
    final rows = await db.query('intercourse', orderBy: 'date ASC');
    return rows.map(IntercourseEntry.fromMap).toList();
  }

  Future<void> saveIntercourse(IntercourseEntry e) async {
    final db = await database;
    if (e.id != null) {
      await db.update('intercourse', e.toMap(),
          where: 'id = ?', whereArgs: [e.id]);
    } else {
      await db.insert('intercourse', e.toMap()..remove('id'));
    }
  }

  Future<void> deleteIntercourse(int id) async {
    final db = await database;
    await db.delete('intercourse', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Maintenance ----------
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('periods');
    await db.delete('moods');
    await db.delete('symptoms');
    await db.delete('intercourse');
  }

  Future<void> importAll({
    required List<PeriodEntry> periods,
    required List<MoodEntry> moods,
    required List<SymptomEntry> symptoms,
    required List<IntercourseEntry> intercourse,
  }) async {
    final db = await database;
    await clearAll();
    final batch = db.batch();
    for (final e in periods) {
      batch.insert('periods', e.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final e in moods) {
      batch.insert('moods', e.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final e in symptoms) {
      batch.insert('symptoms', e.toMap()..remove('id'));
    }
    for (final e in intercourse) {
      batch.insert('intercourse', e.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }
}
