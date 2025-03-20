import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class Contactlocal {
  static Database? _database;
  static final Completer<Database> _dbCompleter = Completer<Database>();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _dbCompleter.future;
  }

  Future<void> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'contacts.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id TEXT PRIMARY KEY,
            name TEXT,
            phoneNumber TEXT UNIQUE,
            photo TEXT
          )
        ''');
      },
    );
    _database = db;
    _dbCompleter.complete(db);
  }

  Contactlocal() {
    _initDatabase();
  }

  Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final db = await database;
    final batch = db.batch();

    for (var contact in contacts) {
      batch.insert(
        'contacts',
        contact,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  Future<void> clearContacts() async {
    final db = await database;
    await db.delete('contacts');
  }
}
