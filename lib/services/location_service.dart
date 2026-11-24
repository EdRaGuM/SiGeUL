import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationDatabaseService {
  static final LocationDatabaseService _instance = LocationDatabaseService._internal();
  factory LocationDatabaseService() => _instance;
  LocationDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'piuttec_locations.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertLocation(double lat, double lng) async {
    final db = await database;
    return await db.insert('locations', {
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toString().substring(0, 19),
    });
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('locations', orderBy: 'id DESC');
  }
}