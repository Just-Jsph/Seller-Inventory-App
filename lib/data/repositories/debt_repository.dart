import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/debt_model.dart';
import '../models/debt_item_model.dart';
import '../models/debt_payment_model.dart';

class DebtRepository {
  final DatabaseHelper _dbHelper;

  DebtRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<DebtModel>> getAll(int userId, {String? status}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.debts,
      where: status != null ? 'user_id = ? AND status = ?' : 'user_id = ?',
      whereArgs: status != null ? [userId, status] : [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  Future<DebtModel?> getById(int userId, int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.debts,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DebtModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DebtItemModel>> getItemsForDebt(int debtId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.debtItems,
      where: 'debt_id = ?',
      whereArgs: [debtId],
    );
    return maps.map((map) => DebtItemModel.fromMap(map)).toList();
  }

  Future<List<DebtPaymentModel>> getPaymentsForDebt(int userId, int debtId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppTables.debtPayments,
      where: 'user_id = ? AND debt_id = ?',
      whereArgs: [userId, debtId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => DebtPaymentModel.fromMap(map)).toList();
  }

  /// Create debt along with its items in a single transaction
  Future<int> createDebtWithItems(DebtModel debt, List<DebtItemModel> items) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final debtId = await txn.insert(AppTables.debts, debt.toMap());
      final now = DateTime.now().toIso8601String();

      for (final item in items) {
        final itemWithDebtId = item.copyWith(debtId: debtId);
        await txn.insert(AppTables.debtItems, itemWithDebtId.toMap());

        // Deduct inventory stock for the user
        await txn.rawUpdate(
          '''
          UPDATE ${AppTables.products}
          SET stock_quantity = stock_quantity - ?, updated_at = ?
          WHERE user_id = ? AND id = ?
          ''',
          [item.quantity, now, debt.userId, item.productId],
        );

        // Record inventory transaction
        await txn.insert(AppTables.inventoryTransactions, {
          'user_id': debt.userId,
          'product_id': item.productId,
          'transaction_type': 'SALE',
          'quantity': -item.quantity,
          'unit_cost_cents': 0,
          'note': 'Credit / Debt for ${debt.customerName}',
          'reference_id': 'DEBT-$debtId',
          'created_at': now,
          'updated_at': now,
        });
      }

      return debtId;
    });
  }

  /// Record a payment towards a customer debt and update debt balance & status
  Future<int> recordPayment(DebtPaymentModel payment) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final paymentId = await txn.insert(AppTables.debtPayments, payment.toMap());

      // Fetch current debt details for user
      final debtMaps = await txn.query(
        AppTables.debts,
        where: 'user_id = ? AND id = ?',
        whereArgs: [payment.userId, payment.debtId],
        limit: 1,
      );

      if (debtMaps.isNotEmpty) {
        final debt = DebtModel.fromMap(debtMaps.first);
        final newPaidAmountCents = debt.paidAmountCents + payment.amountCents;
        final String newStatus =
            newPaidAmountCents >= debt.totalAmountCents ? 'PAID' : 'PARTIAL';

        await txn.update(
          AppTables.debts,
          {
            'paid_amount_cents': newPaidAmountCents,
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ? AND id = ?',
          whereArgs: [payment.userId, payment.debtId],
        );
      }

      return paymentId;
    });
  }

  Future<int> insert(DebtModel item) async {
    final db = await _dbHelper.database;
    return await db.insert(AppTables.debts, item.toMap());
  }

  Future<int> update(DebtModel item) async {
    final db = await _dbHelper.database;
    final updated = item.copyWith(updatedAt: DateTime.now());
    return await db.update(
      AppTables.debts,
      updated.toMap(),
      where: 'user_id = ? AND id = ?',
      whereArgs: [item.userId, item.id],
    );
  }

  Future<int> delete(int userId, int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppTables.debts,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
