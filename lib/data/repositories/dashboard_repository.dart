import '../database/database_helper.dart';
import '../database/tables.dart';

class DailySalesData {
  final DateTime date;
  final String dayLabel;
  final int totalSalesCents;
  final int transactionCount;

  DailySalesData({
    required this.date,
    required this.dayLabel,
    required this.totalSalesCents,
    required this.transactionCount,
  });
}

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Get Today's Sales total cents and transaction count for a user
  Future<Map<String, dynamic>> getTodaySales(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(total_amount_cents), 0) as total_sales,
        COUNT(*) as sales_count
      FROM ${AppTables.sales}
      WHERE user_id = ? AND created_at >= ? AND created_at <= ?
      ''',
      [userId, startOfDay, endOfDay],
    );

    final row = result.first;
    return {
      'totalSalesCents': (row['total_sales'] as num?)?.toInt() ?? 0,
      'salesCount': (row['sales_count'] as num?)?.toInt() ?? 0,
    };
  }

  /// Get Today's Cost (COGS from sale items + Operational Expenses today)
  Future<Map<String, dynamic>> getTodayCost(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    // 1. COGS for today's sales
    final cogsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(CAST(si.quantity * si.cost_cents AS INTEGER)), 0) as total_cogs
      FROM ${AppTables.saleItems} si
      JOIN ${AppTables.sales} s ON si.sale_id = s.id
      WHERE s.user_id = ? AND s.created_at >= ? AND s.created_at <= ?
      ''',
      [userId, startOfDay, endOfDay],
    );
    final cogsCents = (cogsResult.first['total_cogs'] as num?)?.toInt() ?? 0;

    // 2. Expenses today
    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_cents), 0) as total_expense
      FROM ${AppTables.expenses}
      WHERE user_id = ? AND expense_date >= ? AND expense_date <= ?
      ''',
      [userId, startOfDay, endOfDay],
    );
    final expenseCents = (expenseResult.first['total_expense'] as num?)?.toInt() ?? 0;

    final totalCostCents = cogsCents + expenseCents;

    return {
      'totalCostCents': totalCostCents,
      'cogsCents': cogsCents,
      'expenseCents': expenseCents,
    };
  }

  /// Get Total Outstanding Debt (sum of unpaid balances across all customer debts)
  Future<int> getTotalDebtCents(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount_cents - paid_amount_cents), 0) as total_debt
      FROM ${AppTables.debts}
      WHERE user_id = ? AND status != 'PAID'
      ''',
      [userId],
    );
    return (result.first['total_debt'] as num?)?.toInt() ?? 0;
  }

  /// Get Number of Debtors (count of unique customers with active unpaid/partial debts)
  Future<int> getNumberOfDebtors(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT customer_name) as debtor_count
      FROM ${AppTables.debts}
      WHERE user_id = ? AND status != 'PAID' AND (total_amount_cents - paid_amount_cents) > 0
      ''',
      [userId],
    );
    return (result.first['debtor_count'] as num?)?.toInt() ?? 0;
  }

  /// Get Daily Sales Chart Data for the last N days (default 7 days)
  Future<List<DailySalesData>> getSalesChartData(int userId, {int days = 7}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final List<DailySalesData> chartData = [];

    // Short day names
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT 
          COALESCE(SUM(total_amount_cents), 0) as total_sales,
          COUNT(*) as sales_count
        FROM ${AppTables.sales}
        WHERE user_id = ? AND created_at >= ? AND created_at <= ?
        ''',
        [userId, start, end],
      );

      final row = result.first;
      final salesCents = (row['total_sales'] as num?)?.toInt() ?? 0;
      final count = (row['sales_count'] as num?)?.toInt() ?? 0;

      // Label format: "Mon", "Tue" or "09/25"
      final dayLabel = days <= 7 ? dayNames[date.weekday - 1] : '${date.month}/${date.day}';

      chartData.add(
        DailySalesData(
          date: date,
          dayLabel: dayLabel,
          totalSalesCents: salesCents,
          transactionCount: count,
        ),
      );
    }

    return chartData;
  }

  /// Get comprehensive report data for a date range (inclusive)
  Future<Map<String, dynamic>> getReportData(int userId, {required DateTime start, required DateTime end}) async {
    final db = await _dbHelper.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    // 1. Total sales and count
    final salesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount_cents), 0) as total_sales,
             COUNT(*) as sales_count
      FROM ${AppTables.sales}
      WHERE user_id = ? AND created_at >= ? AND created_at <= ?
      ''',
      [userId, startIso, endIso],
    );
    final salesRow = salesResult.first;
    final totalSalesCents = (salesRow['total_sales'] as num?)?.toInt() ?? 0;
    final salesCount = (salesRow['sales_count'] as num?)?.toInt() ?? 0;

    // 2. COGS from sale items
    final cogsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(CAST(si.quantity * si.cost_cents AS INTEGER)), 0) as total_cogs
      FROM ${AppTables.saleItems} si
      JOIN ${AppTables.sales} s ON si.sale_id = s.id
      WHERE s.user_id = ? AND s.created_at >= ? AND s.created_at <= ?
      ''',
      [userId, startIso, endIso],
    );
    final cogsCents = (cogsResult.first['total_cogs'] as num?)?.toInt() ?? 0;

    // 3. Expenses
    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_cents), 0) as total_expense
      FROM ${AppTables.expenses}
      WHERE user_id = ? AND expense_date >= ? AND expense_date <= ?
      ''',
      [userId, startIso, endIso],
    );
    final expenseCents = (expenseResult.first['total_expense'] as num?)?.toInt() ?? 0;

    // 4. Gross and Net profit
    final grossProfitCents = totalSalesCents - cogsCents;
    final netProfitCents = grossProfitCents - expenseCents;

    return {
      'totalSalesCents': totalSalesCents,
      'salesCount': salesCount,
      'cogsCents': cogsCents,
      'expenseCents': expenseCents,
      'grossProfitCents': grossProfitCents,
      'netProfitCents': netProfitCents,
    };
  }

  /// Get sales grouped by product within a date range
  Future<List<Map<String, dynamic>>> getSalesByProduct(int userId, {required DateTime start, required DateTime end}) async {
    final db = await _dbHelper.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT p.id as product_id, p.name as product_name,
             COALESCE(SUM(si.quantity), 0) as total_quantity,
             COALESCE(SUM(si.total_price_cents), 0) as total_sales_cents
      FROM ${AppTables.saleItems} si
      JOIN ${AppTables.sales} s ON si.sale_id = s.id
      JOIN ${AppTables.products} p ON si.product_id = p.id
      WHERE s.user_id = ? AND s.created_at >= ? AND s.created_at <= ?
      GROUP BY p.id, p.name
      ORDER BY total_sales_cents DESC
      ''',
      [userId, startIso, endIso],
    );
    return result;
  }

  /// Get sales grouped by payment method within a date range
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(int userId, {required DateTime start, required DateTime end}) async {
    final db = await _dbHelper.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT payment_method,
             COALESCE(SUM(total_amount_cents), 0) as total_sales_cents,
             COUNT(*) as transaction_count
      FROM ${AppTables.sales}
      WHERE user_id = ? AND created_at >= ? AND created_at <= ?
      GROUP BY payment_method
      ''',
      [userId, startIso, endIso],
    );
    return result;
  }

  // Close class


}
