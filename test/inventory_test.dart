import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_business_manager/data/database/database_helper.dart';
import 'package:small_business_manager/data/database/tables.dart';
import 'package:small_business_manager/data/models/product_model.dart';
import 'package:small_business_manager/data/repositories/user_repository.dart';
import 'package:small_business_manager/data/repositories/product_repository.dart';
import 'package:small_business_manager/data/repositories/category_repository.dart';
import 'package:small_business_manager/data/repositories/inventory_repository.dart';
import 'package:small_business_manager/data/services/auth_service.dart';
import 'package:small_business_manager/data/services/inventory_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late UserRepository userRepo;
  late AuthService authService;
  late ProductRepository productRepo;
  late CategoryRepository categoryRepo;
  late InventoryRepository inventoryRepo;
  late InventoryService inventoryService;

  late int testUserId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.forTesting(path: inMemoryDatabasePath);
    userRepo = UserRepository(dbHelper: dbHelper);
    authService = AuthService(userRepo: userRepo);
    productRepo = ProductRepository(dbHelper: dbHelper);
    categoryRepo = CategoryRepository(dbHelper: dbHelper);
    inventoryRepo = InventoryRepository(dbHelper: dbHelper);
    inventoryService = InventoryService(
      dbHelper: dbHelper,
      productRepo: productRepo,
      categoryRepo: categoryRepo,
      inventoryRepo: inventoryRepo,
    );

    // Create test user
    final user = await authService.register(
      name: 'Inventory Tester',
      usernameOrEmail: 'inventory@test.com',
      password: 'password123',
    );
    testUserId = user.id!;
  });

  tearDown(() async {
    await dbHelper.deleteDb();
  });

  group('Complete Inventory System Tests', () {
    test('1. Add product with initial stock creates product and initial STOCK_IN transaction', () async {
      final category = await inventoryService.addCategory(testUserId, 'Beverages');

      final product = ProductModel(
        userId: testUserId,
        categoryId: category.id,
        name: 'Arabica Coffee Beans 500g',
        sku: 'COF-001',
        barcode: '123456789012',
        buyPriceCents: 45000, // ₱450.00
        sellPriceCents: 65000, // ₱650.00
        unit: 'pack',
        minStockAlert: 10.0,
      );

      final createdProduct = await inventoryService.addProduct(
        product: product,
        initialStock: 25.0,
        note: 'Opening Inventory Batch',
      );

      expect(createdProduct.id, isNotNull);
      expect(createdProduct.name, equals('Arabica Coffee Beans 500g'));
      expect(createdProduct.stockQuantity, equals(25.0));

      // Verify product in database
      final fetched = await inventoryService.getProductById(testUserId, createdProduct.id!);
      expect(fetched, isNotNull);
      expect(fetched!.stockQuantity, equals(25.0));
      expect(fetched.buyPriceCents, equals(45000));
      expect(fetched.sellPriceCents, equals(65000));

      // Verify initial inventory transaction was recorded
      final transactions = await inventoryService.getTransactions(testUserId, productId: createdProduct.id!);
      expect(transactions.length, equals(1));
      expect(transactions.first.transactionType, equals('STOCK_IN'));
      expect(transactions.first.quantity, equals(25.0));
      expect(transactions.first.unitCostCents, equals(45000));
      expect(transactions.first.referenceId, equals('INITIAL_STOCK'));
      expect(transactions.first.productName, equals('Arabica Coffee Beans 500g'));
    });

    test('2. Restocking an existing product atomically updates stock and logs STOCK_IN movement', () async {
      // 1. Create product with initial stock 10
      final product = await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          name: 'Green Tea Box',
          buyPriceCents: 15000,
          sellPriceCents: 22000,
          unit: 'box',
          minStockAlert: 5.0,
        ),
        initialStock: 10.0,
      );

      // 2. Restock 15 boxes
      await inventoryService.restockProduct(
        userId: testUserId,
        productId: product.id!,
        quantity: 15.0,
        unitCostCents: 14500,
        note: 'Supplier Batch Delivery',
        referenceId: 'PO-2026-001',
      );

      // 3. Verify updated stock is 10 + 15 = 25
      final updatedProduct = await inventoryService.getProductById(testUserId, product.id!);
      expect(updatedProduct!.stockQuantity, equals(25.0));

      // 4. Verify transaction records
      final txs = await inventoryService.getTransactions(testUserId, productId: product.id!);
      expect(txs.length, equals(2)); // Initial stock + restock
      expect(txs.first.transactionType, equals('STOCK_IN'));
      expect(txs.first.quantity, equals(15.0));
      expect(txs.first.unitCostCents, equals(14500));
      expect(txs.first.referenceId, equals('PO-2026-001'));
      expect(txs.first.note, equals('Supplier Batch Delivery'));
    });

    test('3. Stock adjustment correctly computes delta and logs ADJUSTMENT transaction', () async {
      final product = await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          name: 'Sugar 1kg',
          buyPriceCents: 5000,
          sellPriceCents: 7500,
          unit: 'kg',
          minStockAlert: 5.0,
        ),
        initialStock: 20.0,
      );

      // Audit reveals only 18 kg on shelf (2 kg missing / damage)
      await inventoryService.adjustStock(
        userId: testUserId,
        productId: product.id!,
        newQuantity: 18.0,
        reason: 'Physical Audit Correction (2kg damaged/lost)',
      );

      final updated = await inventoryService.getProductById(testUserId, product.id!);
      expect(updated!.stockQuantity, equals(18.0));

      final txs = await inventoryService.getTransactions(testUserId, productId: product.id!);
      expect(txs.length, equals(2));
      final adjTx = txs.first;
      expect(adjTx.transactionType, equals('ADJUSTMENT'));
      expect(adjTx.quantity, equals(-2.0)); // Delta is -2.0
      expect(adjTx.note, contains('Physical Audit Correction'));
    });

    test('4. Edit product details updates metadata while preserving stock levels', () async {
      final product = await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          name: 'Old Product Name',
          buyPriceCents: 1000,
          sellPriceCents: 2000,
          unit: 'pcs',
          minStockAlert: 5.0,
        ),
        initialStock: 30.0,
      );

      final toUpdate = product.copyWith(
        name: 'New Premium Product Name',
        sellPriceCents: 2500,
        minStockAlert: 8.0,
      );

      await inventoryService.updateProduct(toUpdate);

      final updated = await inventoryService.getProductById(testUserId, product.id!);
      expect(updated!.name, equals('New Premium Product Name'));
      expect(updated.sellPriceCents, equals(2500));
      expect(updated.minStockAlert, equals(8.0));
      expect(updated.stockQuantity, equals(30.0)); // Stock unaffected
    });

    test('5. Product deletion safety: prevents deletion if sales records exist', () async {
      final product = await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          name: 'Sold Item',
          buyPriceCents: 1000,
          sellPriceCents: 1500,
        ),
        initialStock: 10.0,
      );

      // Simulate a sale record referencing this product
      final db = await dbHelper.database;
      final saleId = await db.insert(AppTables.sales, {
        'user_id': testUserId,
        'invoice_number': 'INV-001',
        'total_amount_cents': 1500,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert(AppTables.saleItems, {
        'sale_id': saleId,
        'product_id': product.id,
        'product_name': product.name,
        'quantity': 1.0,
        'unit_price_cents': 1500,
        'subtotal_cents': 1500,
        'cost_cents': 1000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Check can delete
      final check = await inventoryService.canDeleteProduct(testUserId, product.id!);
      expect(check.canDelete, isFalse);
      expect(check.reason, contains('sales transactions'));

      // Attempting to delete throws exception
      expect(
        () => inventoryService.deleteProduct(testUserId, product.id!),
        throwsException,
      );
    });

    test('6. Product deletion succeeds if no conflicting history', () async {
      final product = await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          name: 'Temporary Item',
          buyPriceCents: 1000,
          sellPriceCents: 1500,
        ),
        initialStock: 5.0,
      );

      final check = await inventoryService.canDeleteProduct(testUserId, product.id!);
      expect(check.canDelete, isTrue);

      await inventoryService.deleteProduct(testUserId, product.id!);

      final fetched = await inventoryService.getProductById(testUserId, product.id!);
      expect(fetched, isNull);

      final txs = await inventoryService.getTransactions(testUserId, productId: product.id!);
      expect(txs, isEmpty);
    });

    test('7. Search, Category, Low-Stock, and Out-of-Stock filtering', () async {
      final catSnacks = await inventoryService.addCategory(testUserId, 'Snacks');
      final catDrinks = await inventoryService.addCategory(testUserId, 'Drinks');

      // Product 1: Normal In-Stock (Snacks)
      await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          categoryId: catSnacks.id,
          name: 'Potato Chips BBQ',
          sku: 'CHP-01',
          buyPriceCents: 3000,
          sellPriceCents: 5000,
          minStockAlert: 5.0,
        ),
        initialStock: 20.0,
      );

      // Product 2: Low-Stock (Drinks)
      await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          categoryId: catDrinks.id,
          name: 'Orange Juice 1L',
          sku: 'OJC-01',
          buyPriceCents: 4000,
          sellPriceCents: 7000,
          minStockAlert: 10.0,
        ),
        initialStock: 3.0, // <= 10 -> Low stock
      );

      // Product 3: Out-of-Stock (Snacks)
      await inventoryService.addProduct(
        product: ProductModel(
          userId: testUserId,
          categoryId: catSnacks.id,
          name: 'Chocolate Bar Dark',
          sku: 'CHO-01',
          buyPriceCents: 2000,
          sellPriceCents: 3500,
          minStockAlert: 5.0,
        ),
        initialStock: 0.0, // Out of stock
      );

      // Test 7a: Get All
      final all = await inventoryService.getProducts(testUserId);
      expect(all.length, equals(3));

      // Test 7b: Search query 'Chips'
      final searchChips = await inventoryService.getProducts(testUserId, query: 'Chips');
      expect(searchChips.length, equals(1));
      expect(searchChips.first.name, equals('Potato Chips BBQ'));

      // Test 7c: Search query SKU 'CHO-01'
      final searchSku = await inventoryService.getProducts(testUserId, query: 'CHO-01');
      expect(searchSku.length, equals(1));
      expect(searchSku.first.name, equals('Chocolate Bar Dark'));

      // Test 7d: Filter by Category Drinks
      final drinksOnly = await inventoryService.getProducts(testUserId, categoryId: catDrinks.id);
      expect(drinksOnly.length, equals(1));
      expect(drinksOnly.first.name, equals('Orange Juice 1L'));

      // Test 7e: Filter Low Stock
      final lowStock = await inventoryService.getProducts(testUserId, filter: StockFilter.lowStock);
      expect(lowStock.length, equals(1));
      expect(lowStock.first.name, equals('Orange Juice 1L'));

      // Test 7f: Filter Out of Stock
      final outOfStock = await inventoryService.getProducts(testUserId, filter: StockFilter.outOfStock);
      expect(outOfStock.length, equals(1));
      expect(outOfStock.first.name, equals('Chocolate Bar Dark'));

      // Test 7g: Filter In Stock
      final inStock = await inventoryService.getProducts(testUserId, filter: StockFilter.inStock);
      expect(inStock.length, equals(1));
      expect(inStock.first.name, equals('Potato Chips BBQ'));

      // Test 7h: Inventory Summary Valuations
      final summary = await inventoryService.getInventorySummary(testUserId);
      expect(summary.totalProducts, equals(3));
      expect(summary.inStockCount, equals(1));
      expect(summary.lowStockCount, equals(1));
      expect(summary.outOfStockCount, equals(1));
      // Total cost: (20 * 3000) + (3 * 4000) + (0 * 2000) = 60000 + 12000 = 72000 cents (₱720.00)
      expect(summary.totalCostCents, equals(72000));
      // Total retail: (20 * 5000) + (3 * 7000) + (0 * 3500) = 100000 + 21000 = 121000 cents (₱1,210.00)
      expect(summary.totalRetailCents, equals(121000));
    });
  });
}
