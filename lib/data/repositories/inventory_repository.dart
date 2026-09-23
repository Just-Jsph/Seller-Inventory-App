import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/inventory_transaction_model.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper;

  InventoryRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Retrieve all inventory transactions for a user, joined with product name and unit
  Future<List<InventoryTransactionModel>> getAll(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        it.*,
        p.name AS product_name,
        p.unit AS unit
      FROM ${AppTables.inventoryTransactions} it
      LEFT JOIN ${AppTables.products} p ON it.product_id = p.id
      WHERE it.user_id = ?
      ORDER BY it.created_at DESC
      ''',
      [userId],
    );
    return maps.map((map) => InventoryTransactionModel.fromMap(map)).toList();
  }

  Future<InventoryTransactionModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        it.*,
        p.name AS product_name,
        p.unit AS unit
      FROM ${AppTables.inventoryTransactions} it
      LEFT JOIN ${AppTables.products} p ON it.product_id = p.id
      WHERE it.user_id = ? AND it.id = ?
      LIMIT 1
      ''',
      [userId, id],
    );
    if (maps.isNotEmpty) {
      return InventoryTransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<InventoryTransactionModel>> getByProductId(int userId, int productId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        it.*,
        p.name AS product_name,
        p.unit AS unit
      FROM ${AppTables.inventoryTransactions} it
      LEFT JOIN ${AppTables.products} p ON it.product_id = p.id
      WHERE it.user_id = ? AND it.product_id = ?
      ORDER BY it.created_at DESC
      ''',
      [userId, productId],
    );
    return maps.map((map) => InventoryTransactionModel.fromMap(map)).toList();
  }

  /// Filter transactions by optional type and product
  Future<List<InventoryTransactionModel>> getFiltered(
    int userId, {
    int? productId,
    String? transactionType,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = ['it.user_id = ?'];
    final List<dynamic> whereArgs = [userId];

    if (productId != null) {
      whereClauses.add('it.product_id = ?');
      whereArgs.add(productId);
    }

    if (transactionType != null && transactionType.isNotEmpty && transactionType != 'ALL') {
      whereClauses.add('it.transaction_type = ?');
      whereArgs.add(transactionType);
    }

    final String query = '''
      SELECT 
        it.*,
        p.name AS product_name,
        p.unit AS unit
      FROM ${AppTables.inventoryTransactions} it
      LEFT JOIN ${AppTables.products} p ON it.product_id = p.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY it.created_at DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
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
      } else if (item.transactionType == 'ADJUSTMENT') {
        // Quantity passed directly represents delta (can be positive or negative)
        delta = item.quantity;
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
