import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/inventory_transaction_model.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper;

  InventoryRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<InventoryTransactionModel>> getAll(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.inventoryTransactions,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryTransactionModel.fromMap(map)).toList();
  }

  Future<InventoryTransactionModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.inventoryTransactions,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return InventoryTransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<InventoryTransactionModel>> getByProductId(int userId, int productId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.inventoryTransactions,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryTransactionModel.fromMap(map)).toList();
  }

  /// Record an inventory transaction and automatically adjust product stock atomically
  Future<int> insert(InventoryTransactionModel item) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final txId = await txn.insert(AppTables.inventoryTransactions, item.toMap());

      // Determine stock delta based on transaction type
      double delta = item.quantity;
      if (item.transactionType == 'STOCK_OUT' ||
          item.transactionType == 'SALE' ||
          item.transactionType == 'DAMAGE') {
        delta = -item.quantity.abs();
      } else if (item.transactionType == 'STOCK_IN' || item.transactionType == 'RETURN') {
        delta = item.quantity.abs();
      }

      await txn.rawUpdate(
        '''
        UPDATE ${AppTables.products}
        SET stock_quantity = stock_quantity + ?, updated_at = ?
        WHERE user_id = ? AND id = ?
        ''',
        [delta, DateTime.now().toIso8601String(), item.userId, item.productId],
      );

      return txId;
    });
  }

  Future<int> update(InventoryTransactionModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.inventoryTransactions,
      updated.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.inventoryTransactions,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
