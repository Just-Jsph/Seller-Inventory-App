import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper;

  SaleRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<SaleModel>> getAll(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.sales,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SaleModel.fromMap(map)).toList();
  }

  Future<SaleModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.sales,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return SaleModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SaleItemModel>> getItemsForSale(int saleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.saleItems,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItemModel.fromMap(map)).toList();
  }

  Future<List<SaleModel>> getSalesByDateRange(int userId, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.sales,
      where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SaleModel.fromMap(map)).toList();
  }

  /// Create a sale with its sale items and update inventory atomically
  Future<int> createSaleWithItems(SaleModel sale, List<SaleItemModel> items) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      // 1. Insert parent sale
      final saleId = await txn.insert(AppTables.sales, sale.toMap());

      // 2. Insert items & update product stock
      final now = DateTime.now().toIso8601String();
      for (final item in items) {
        final itemWithSaleId = item.copyWith(saleId: saleId);
        await txn.insert(AppTables.saleItems, itemWithSaleId.toMap());

        // Deduct inventory stock for the user
        await txn.rawUpdate(
          '''
          UPDATE ${AppTables.products}
          SET stock_quantity = stock_quantity - ?, updated_at = ?
          WHERE user_id = ? AND id = ?
          ''',
          [item.quantity, now, sale.userId, item.productId],
        );

        // Record inventory transaction
        await txn.insert(AppTables.inventoryTransactions, {
          'user_id': sale.userId,
          'product_id': item.productId,
          'transaction_type': 'SALE',
          'quantity': -item.quantity,
          'unit_cost_cents': item.costCents,
          'note': 'Sale #${sale.invoiceNumber}',
          'reference_id': saleId.toString(),
          'created_at': now,
          'updated_at': now,
        });
      }

      return saleId;
    });
  }

  Future<int> insert(SaleModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(AppTables.sales, item.toMap());
  }

  Future<int> update(SaleModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.sales,
      updated.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.sales,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
