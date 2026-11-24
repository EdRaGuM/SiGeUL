import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }
  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'mb_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            user TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password TEXT,
            image_path TEXT
          )
        ''');
        print('Tabla "users" creada correctamente.');

        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');

        print('Tabla "locations" creada correctamente.');
      },
    );
  }
}