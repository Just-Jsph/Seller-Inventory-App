import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<ProductModel>> getAll(int userId, {bool activeOnly = true}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<ProductModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<ProductModel?> getByBarcode(int userId, String barcode) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: 'user_id = ? AND barcode = ? AND is_active = 1',
      whereArgs: [userId, barcode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ProductModel>> getByCategory(int userId, int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: 'user_id = ? AND category_id = ? AND is_active = 1',
      whereArgs: [userId, categoryId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> getLowStockProducts(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: 'user_id = ? AND stock_quantity <= min_stock_alert AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'stock_quantity ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> search(int userId, String query) async {
    final db = await _dbHelper.database;
    final cleanQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.products,
      where: 'user_id = ? AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?) AND is_active = 1',
      whereArgs: [userId, cleanQuery, cleanQuery, cleanQuery],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> insert(ProductModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppTables.products,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(ProductModel item) async {
    final db = await _dbHelper.database;
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.products,
      updatedItem.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> updateStock(int userId, int productId, double quantityDelta, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _dbHelper.database;
    return await db.rawUpdate(
      '''
      UPDATE ${AppTables.products}
      SET stock_quantity = stock_quantity + ?, updated_at = ?
      WHERE user_id = ? AND id = ?
      ''',
      [quantityDelta, DateTime.now().toIso8601String(), userId, productId],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.products,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
