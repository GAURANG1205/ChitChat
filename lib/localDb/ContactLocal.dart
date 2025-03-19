import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Contactlocal {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'contacts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id TEXT PRIMARY KEY,
            name TEXT,
            phoneNumber TEXT UNIQUE,
            photo BLOB
          )
        ''');
      },
    );
  }

  Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var contact in contacts) {
        await txn.insert(
          'contacts',
          contact,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
