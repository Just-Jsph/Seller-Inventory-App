import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/inventory_transaction_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/inventory_repository.dart';

enum StockFilter {
  all,
  lowStock,
  outOfStock,
  inStock,
}

class InventorySummary {
  final int totalProducts;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalCostCents;
  final int totalRetailCents;

  const InventorySummary({
    required this.totalProducts,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalCostCents,
    required this.totalRetailCents,
  });

  factory InventorySummary.empty() => const InventorySummary(
        totalProducts: 0,
        inStockCount: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
        totalCostCents: 0,
        totalRetailCents: 0,
      );
}

class CanDeleteResult {
  final bool canDelete;
  final String? reason;

  const CanDeleteResult({required this.canDelete, this.reason});
}

class InventoryService {
  final DatabaseHelper _dbHelper;
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final InventoryRepository _inventoryRepo;

  InventoryService({
    DatabaseHelper? dbHelper,
    ProductRepository? productRepo,
    CategoryRepository? categoryRepo,
    InventoryRepository? inventoryRepo,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _productRepo = productRepo ?? ProductRepository(dbHelper: dbHelper),
        _categoryRepo = categoryRepo ?? CategoryRepository(dbHelper: dbHelper),
        _inventoryRepo = inventoryRepo ?? InventoryRepository(dbHelper: dbHelper);

  /// Fetch products with flexible filtering (search query, category, stock state)
  Future<List<ProductModel>> getProducts(
    int userId, {
    String? query,
    int? categoryId,
    StockFilter filter = StockFilter.all,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = ['user_id = ?', 'is_active = 1'];
    final List<dynamic> whereArgs = [userId];

    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = '%${query.trim()}%';
      whereClauses.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
      whereArgs.addAll([cleanQuery, cleanQuery, cleanQuery]);
    }

    if (categoryId != null && categoryId > 0) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    switch (filter) {
      case StockFilter.lowStock:
        whereClauses.add('stock_quantity > 0 AND stock_quantity <= min_stock_alert');
        break;
      case StockFilter.outOfStock:
        whereClauses.add('stock_quantity <= 0');
        break;
      case StockFilter.inStock:
        whereClauses.add('stock_quantity > min_stock_alert');
        break;
      case StockFilter.all:
        break;
    }

    final String sql = '''
      SELECT * FROM ${AppTables.products}
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY name ASC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  /// Get single product by ID
  Future<ProductModel?> getProductById(int userId, int productId) async {
    return await _productRepo.getById(userId, productId);
  }

  /// Get all categories for a user
  Future<List<CategoryModel>> getCategories(int userId) async {
    return await _categoryRepo.getAll(userId);
  }

  /// Add a new category
  Future<CategoryModel> addCategory(int userId, String name, {String? description}) async {
    final category = CategoryModel(
      userId: userId,
      name: name.trim(),
      description: description?.trim(),
    );
    final id = await _categoryRepo.insert(category);
    return category.copyWith(id: id);
  }

  /// Add a new product and atomically record initial inventory transaction if initialStock > 0
  Future<ProductModel> addProduct({
    required ProductModel product,
    double initialStock = 0.0,
    String? note,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction<ProductModel>((txn) async {
      // 1. Insert product with initial stock
      final productToInsert = product.copyWith(stockQuantity: initialStock);
      final productId = await txn.insert(
        AppTables.products,
        productToInsert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      // 2. Record initial stock movement if initialStock > 0
      if (initialStock > 0) {
        final initialTx = InventoryTransactionModel(
          userId: product.userId,
          productId: productId,
          transactionType: 'STOCK_IN',
          quantity: initialStock,
          unitCostCents: product.buyPriceCents,
          note: note?.trim().isNotEmpty == true ? note!.trim() : 'Initial Stock Creation',
          referenceId: 'INITIAL_STOCK',
        );
        await txn.insert(AppTables.inventoryTransactions, initialTx.toMap());
      }

      return productToInsert.copyWith(id: productId);
    });
  }

  /// Update product metadata
  Future<ProductModel> updateProduct(ProductModel product) async {
    await _productRepo.update(product);
    return product;
  }

  /// Restock an existing product atomically with audit transaction
  Future<void> restockProduct({
    required int userId,
    required int productId,
    required double quantity,
    required int unitCostCents,
    String? note,
    String? referenceId,
    DateTime? date,
    bool updateProductCostPrice = false,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Restock quantity must be greater than 0.');
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = date ?? DateTime.now();

      // 1. Create STOCK_IN transaction
      final tx = InventoryTransactionModel(
        userId: userId,
        productId: productId,
        transactionType: 'STOCK_IN',
        quantity: quantity,
        unitCostCents: unitCostCents,
        note: note?.trim().isNotEmpty == true ? note!.trim() : 'Stock Restock',
        referenceId: referenceId?.trim(),
        createdAt: now,
      );
      await txn.insert(AppTables.inventoryTransactions, tx.toMap());

      // 2. Update product stock and optionally cost price
      if (updateProductCostPrice) {
        await txn.rawUpdate(
          '''
          UPDATE ${AppTables.products}
          SET stock_quantity = stock_quantity + ?,
              buy_price_cents = ?,
              updated_at = ?
          WHERE user_id = ? AND id = ?
          ''',
          [quantity, unitCostCents, DateTime.now().toIso8601String(), userId, productId],
        );
      } else {
        await txn.rawUpdate(
          '''
          UPDATE ${AppTables.products}
          SET stock_quantity = stock_quantity + ?,
              updated_at = ?
          WHERE user_id = ? AND id = ?
          ''',
          [quantity, DateTime.now().toIso8601String(), userId, productId],
        );
      }
    });
  }

  /// Adjust stock level with a specific reason/note (Audit count correction, damage, etc.)
  Future<void> adjustStock({
    required int userId,
    required int productId,
    required double newQuantity,
    required String reason,
    int? unitCostCents,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Get current product stock
      final List<Map<String, dynamic>> res = await txn.query(
        AppTables.products,
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, productId],
        limit: 1,
      );
      if (res.isEmpty) {
        throw Exception('Product not found.');
      }
      final currentStock = (res.first['stock_quantity'] as num).toDouble();
      final buyPrice = (res.first['buy_price_cents'] as int);
      final delta = newQuantity - currentStock;

      if (delta == 0) return; // No change needed

      // 2. Insert ADJUSTMENT transaction
      final tx = InventoryTransactionModel(
        userId: userId,
        productId: productId,
        transactionType: 'ADJUSTMENT',
        quantity: delta,
        unitCostCents: unitCostCents ?? buyPrice,
        note: reason.trim(),
        referenceId: 'AUDIT_ADJUSTMENT',
      );
      await txn.insert(AppTables.inventoryTransactions, tx.toMap());

      // 3. Update product stock to exact new quantity
      await txn.rawUpdate(
        '''
        UPDATE ${AppTables.products}
        SET stock_quantity = ?, updated_at = ?
        WHERE user_id = ? AND id = ?
        ''',
        [newQuantity, DateTime.now().toIso8601String(), userId, productId],
      );
    });
  }

  /// Check if a product can be safely deleted without breaking sales/debts history
  Future<CanDeleteResult> canDeleteProduct(int userId, int productId) async {
    final db = await _dbHelper.database;

    // Check 1: Referenced in sale_items
    final List<Map<String, dynamic>> saleCheck = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${AppTables.saleItems} si
      JOIN ${AppTables.sales} s ON si.sale_id = s.id
      WHERE s.user_id = ? AND si.product_id = ?
      ''',
      [userId, productId],
    );
    final saleCount = Sqflite.firstIntValue(saleCheck) ?? 0;
    if (saleCount > 0) {
      return CanDeleteResult(
        canDelete: false,
        reason: 'Cannot delete: Product is associated with $saleCount recorded sales transactions.',
      );
    }

    // Check 2: Referenced in debt_items
    final List<Map<String, dynamic>> debtCheck = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${AppTables.debtItems} di
      JOIN ${AppTables.debts} d ON di.debt_id = d.id
      WHERE d.user_id = ? AND di.product_id = ?
      ''',
      [userId, productId],
    );
    final debtCount = Sqflite.firstIntValue(debtCheck) ?? 0;
    if (debtCount > 0) {
      return CanDeleteResult(
        canDelete: false,
        reason: 'Cannot delete: Product is associated with $debtCount customer credit/debt items.',
      );
    }

    // Check 3: Check if there are non-initial inventory transactions
    final List<Map<String, dynamic>> txCheck = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${AppTables.inventoryTransactions}
      WHERE user_id = ? AND product_id = ? AND transaction_type != 'STOCK_IN'
      ''',
      [userId, productId],
    );
    final nonInitialCount = Sqflite.firstIntValue(txCheck) ?? 0;
    if (nonInitialCount > 0) {
      return CanDeleteResult(
        canDelete: false,
        reason: 'Cannot delete: Product has $nonInitialCount operational stock movement records (Sales, Adjustments, Returns).',
      );
    }

    return const CanDeleteResult(canDelete: true);
  }

  /// Delete product if safe
  Future<void> deleteProduct(int userId, int productId) async {
    final safetyCheck = await canDeleteProduct(userId, productId);
    if (!safetyCheck.canDelete) {
      throw Exception(safetyCheck.reason ?? 'Cannot delete product due to transaction conflicts.');
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Delete any initial stock transactions for this product
      await txn.delete(
        AppTables.inventoryTransactions,
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );

      // Delete the product
      await txn.delete(
        AppTables.products,
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, productId],
      );
    });
  }

  /// Retrieve inventory movements / transactions
  Future<List<InventoryTransactionModel>> getTransactions(
    int userId, {
    int? productId,
    String? transactionType,
  }) async {
    return await _inventoryRepo.getFiltered(
      userId,
      productId: productId,
      transactionType: transactionType,
    );
  }

  /// Summary metrics for inventory valuations and status
  Future<InventorySummary> getInventorySummary(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_products,
        SUM(CASE WHEN stock_quantity > min_stock_alert THEN 1 ELSE 0 END) as in_stock_count,
        SUM(CASE WHEN stock_quantity > 0 AND stock_quantity <= min_stock_alert THEN 1 ELSE 0 END) as low_stock_count,
        SUM(CASE WHEN stock_quantity <= 0 THEN 1 ELSE 0 END) as out_of_stock_count,
        SUM(stock_quantity * buy_price_cents) as total_cost_cents,
        SUM(stock_quantity * sell_price_cents) as total_retail_cents
      FROM ${AppTables.products}
      WHERE user_id = ? AND is_active = 1
      ''',
      [userId],
    );

    if (maps.isNotEmpty) {
      final row = maps.first;
      return InventorySummary(
        totalProducts: (row['total_products'] as int?) ?? 0,
        inStockCount: (row['in_stock_count'] as int?) ?? 0,
        lowStockCount: (row['low_stock_count'] as int?) ?? 0,
        outOfStockCount: (row['out_of_stock_count'] as int?) ?? 0,
        totalCostCents: ((row['total_cost_cents'] as num?)?.round()) ?? 0,
        totalRetailCents: ((row['total_retail_cents'] as num?)?.round()) ?? 0,
      );
    }

    return InventorySummary.empty();
  }
}
