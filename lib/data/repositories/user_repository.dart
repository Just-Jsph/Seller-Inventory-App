import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<UserModel>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.users,
      orderBy: 'name ASC',
    );
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<UserModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.users,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getByUsername(String username) async {
    final db = await _dbHelper.database;
    final cleanUsername = username.trim().toLowerCase();
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.users,
      where: 'LOWER(username) = ?',
      whereArgs: [cleanUsername],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insert(UserModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppTables.users,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(UserModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.users,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.users,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
