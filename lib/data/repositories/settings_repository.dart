import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/setting_model.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper;

  SettingsRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<String?> get(String key, {String? defaultValue}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.settings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return defaultValue;
  }

  Future<void> set(String key, String value) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      AppTables.settings,
      {
        'key': key,
        'value': value,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SettingModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(AppTables.settings);
    return maps.map((map) => SettingModel.fromMap(map)).toList();
  }

  Future<int> delete(String key) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.settings,
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}
