import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper;

  ExpenseRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<ExpenseModel>> getAll(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.expenses,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<ExpenseModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.expenses,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ExpenseModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ExpenseModel>> getByDateRange(int userId, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.expenses,
      where: 'user_id = ? AND expense_date >= ? AND expense_date <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<int> getTotalExpensesCents(int userId, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount_cents) as total
      FROM ${AppTables.expenses}
      WHERE user_id = ? AND expense_date >= ? AND expense_date <= ?
      ''',
      [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> insert(ExpenseModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppTables.expenses,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(ExpenseModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.expenses,
      updated.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.expenses,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
