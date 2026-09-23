import 'package:sqflite/sqflite.dart';
import 'tables.dart';

/// Database version management and migration handlers
class DatabaseMigrations {
  static const int currentVersion = 1;

  /// Execute initial database creation
  static Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();

    // Create all 11 relational tables
    batch.execute(AppTables.createUsersTable);
    batch.execute(AppTables.createCategoriesTable);
    batch.execute(AppTables.createProductsTable);
    batch.execute(AppTables.createInventoryTransactionsTable);
    batch.execute(AppTables.createSalesTable);
    batch.execute(AppTables.createSaleItemsTable);
    batch.execute(AppTables.createDebtsTable);
    batch.execute(AppTables.createDebtItemsTable);
    batch.execute(AppTables.createDebtPaymentsTable);
    batch.execute(AppTables.createExpensesTable);
    batch.execute(AppTables.createSettingsTable);

    // Create performance indexes
    for (final indexQuery in AppTables.createIndexes) {
      batch.execute(indexQuery);
    }

    await batch.commit(noResult: true);
  }

  /// Execute incremental migrations on database upgrade
  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigrationForVersion(db, version);
    }
  }

  static Future<void> _runMigrationForVersion(Database db, int version) async {
    switch (version) {
      default:
        break;
    }
  }
}
