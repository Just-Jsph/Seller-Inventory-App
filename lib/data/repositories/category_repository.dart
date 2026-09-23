import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<CategoryModel>> getAll(int userId, {bool activeOnly = true}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.categories,
      where: activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.categories,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insert(CategoryModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppTables.categories,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(CategoryModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.categories,
      updated.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.categories,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
