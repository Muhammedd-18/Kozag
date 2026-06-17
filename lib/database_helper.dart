import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kozag.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tc_no TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      maiden_name TEXT NOT NULL,
      is_pregnant INTEGER NOT NULL,
      pregnancy_week INTEGER,
      registration_date TEXT 
    )
    ''');
    await db.execute('''
    CREATE TABLE children (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL,
      child_name TEXT NOT NULL,
      birth_date TEXT, birth_time TEXT, birth_place TEXT,
      gestation_week INTEGER, gender TEXT, weight_gr INTEGER,
      height REAL, head_circumference REAL, is_multiple_pregnancy INTEGER,
      delivery_type TEXT, doctor_name TEXT, midwives TEXT,
      birth_fever REAL, has_disease INTEGER, diseases TEXT, 
      is_premature INTEGER, in_incubator INTEGER, incubator_days INTEGER, vaccines TEXT,
      FOREIGN KEY (parent_id) REFERENCES users (id)
    )
    ''');
    await db.execute('''
    CREATE TABLE daily_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      water_drank REAL,
      love_count INTEGER DEFAULT 0, 
      diet_data TEXT,
      exercise_data TEXT,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''');
    await db.execute('''
      INSERT INTO users (tc_no, name, maiden_name, is_pregnant, pregnancy_week, registration_date) 
      VALUES ('admin', 'Admin', 'admin', 0, 0, '${DateTime.now().toIso8601String()}')
    ''');
  }

  Future<int> createUser(Map<String, dynamic> user) async => await (await instance.database).insert('users', user);
  Future<int> createChild(Map<String, dynamic> child) async => await (await instance.database).insert('children', child);
  Future<Map<String, dynamic>?> loginUser(String tcNo, String maidenName) async {
    final res = await (await instance.database).query('users', where: 'tc_no = ? AND maiden_name = ?', whereArgs: [tcNo, maidenName]);
    return res.isNotEmpty ? res.first : null;
  }
  Future<Map<String, dynamic>?> getDailyLog(int userId, String date) async {
    final res = await (await instance.database).query('daily_logs', where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
    return res.isNotEmpty ? res.first : null;
  }
  Future<int> insertDailyLog(Map<String, dynamic> log) async => await (await instance.database).insert('daily_logs', log);
  Future<int> updateDailyLog(int userId, String date, Map<String, dynamic> log) async => await (await instance.database).update('daily_logs', log, where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
}