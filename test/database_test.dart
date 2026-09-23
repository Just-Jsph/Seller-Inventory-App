import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_business_manager/data/database/database_helper.dart';
import 'package:small_business_manager/data/database/tables.dart';
import 'package:small_business_manager/data/models/user_model.dart';
import 'package:small_business_manager/data/models/product_model.dart';
import 'package:small_business_manager/data/models/category_model.dart';
import 'package:small_business_manager/data/models/inventory_transaction_model.dart';
import 'package:small_business_manager/data/repositories/user_repository.dart';
import 'package:small_business_manager/data/repositories/product_repository.dart';
import 'package:small_business_manager/data/repositories/category_repository.dart';
import 'package:small_business_manager/data/repositories/inventory_repository.dart';

void main() {
  // Initialize FFI for running SQLite during unit/widget tests on host OS
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late UserRepository userRepo;
  late ProductRepository productRepo;
  late CategoryRepository categoryRepo;
  late InventoryRepository inventoryRepo;
  late int testUserId;

  setUp(() async {
    // Each test gets a fresh in-memory database via the test-only factory
    dbHelper = DatabaseHelper.forTesting(path: inMemoryDatabasePath);
    userRepo = UserRepository(dbHelper: dbHelper);
    productRepo = ProductRepository(dbHelper: dbHelper);
    categoryRepo = CategoryRepository(dbHelper: dbHelper);
    inventoryRepo = InventoryRepository(dbHelper: dbHelper);

    // Create primary test user
    testUserId = await userRepo.insert(
      UserModel(
        name: 'Test Owner',
        username: 'testowner',
        passwordHash: 'dummyhash',
      ),
    );
  });

  tearDown(() async {
    await dbHelper.deleteDb();
  });

  group('SQLite Database CRUD & Relational Tests', () {
    test('Database opens and creates all 11 required tables', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%';",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames.contains(AppTables.users), isTrue);
      expect(tableNames.contains(AppTables.categories), isTrue);
      expect(tableNames.contains(AppTables.products), isTrue);
      expect(tableNames.contains(AppTables.inventoryTransactions), isTrue);
      expect(tableNames.contains(AppTables.sales), isTrue);
      expect(tableNames.contains(AppTables.saleItems), isTrue);
      expect(tableNames.contains(AppTables.debts), isTrue);
      expect(tableNames.contains(AppTables.debtItems), isTrue);
      expect(tableNames.contains(AppTables.debtPayments), isTrue);
      expect(tableNames.contains(AppTables.expenses), isTrue);
      expect(tableNames.contains(AppTables.settings), isTrue);
    });

    test('Product CRUD Operations (Insert, Read, Update, Delete)', () async {
      // 1. Insert Category
      final category = CategoryModel(
        userId: testUserId,
        name: 'Beverages',
        description: 'Cold drinks and juices',
      );
      final catId = await categoryRepo.insert(category);
      expect(catId, isPositive);

      // 2. Insert Test Product
      final testProduct = ProductModel(
        userId: testUserId,
        categoryId: catId,
        name: 'Organic Orange Juice 500ml',
        sku: 'BEV-001',
        barcode: '1234567890123',
        buyPriceCents: 250, // $2.50
        sellPriceCents: 450, // $4.50
        stockQuantity: 50.0,
        minStockAlert: 10.0,
        unit: 'bottle',
      );

      final insertedId = await productRepo.insert(testProduct);
      expect(insertedId, isPositive);

      // 3. Read Test Product
      final retrievedProduct = await productRepo.getById(testUserId, insertedId);
      expect(retrievedProduct, isNotNull);
      expect(retrievedProduct!.name, equals('Organic Orange Juice 500ml'));
      expect(retrievedProduct.buyPriceCents, equals(250));
      expect(retrievedProduct.sellPriceCents, equals(450));
      expect(retrievedProduct.buyPrice, equals(2.50));
      expect(retrievedProduct.sellPrice, equals(4.50));
      expect(retrievedProduct.stockQuantity, equals(50.0));
      expect(retrievedProduct.sku, equals('BEV-001'));
      expect(retrievedProduct.barcode, equals('1234567890123'));

      // 4. Update Test Product
      final updatedProduct = retrievedProduct.copyWith(
        name: 'Organic Orange Juice 1L',
        sellPriceCents: 750, // $7.50
        stockQuantity: 40.0,
      );
      final updateRows = await productRepo.update(updatedProduct);
      expect(updateRows, equals(1));

      final fetchedUpdated = await productRepo.getById(testUserId, insertedId);
      expect(fetchedUpdated!.name, equals('Organic Orange Juice 1L'));
      expect(fetchedUpdated.sellPriceCents, equals(750));
      expect(fetchedUpdated.sellPrice, equals(7.50));
      expect(fetchedUpdated.stockQuantity, equals(40.0));

      // 5. Delete Test Product
      final deleteRows = await productRepo.delete(testUserId, insertedId);
      expect(deleteRows, equals(1));

      // 6. Verify Deletion
      final deletedProduct = await productRepo.getById(testUserId, insertedId);
      expect(deletedProduct, isNull);

      // Clean up category
      await categoryRepo.delete(testUserId, catId);
    });

    test('Inventory transaction automatically adjusts product stock atomically', () async {
      // Create product with initial stock = 10
      final prodId = await productRepo.insert(
        ProductModel(
          userId: testUserId,
          name: 'Coffee Beans 1kg',
          buyPriceCents: 1200,
          sellPriceCents: 2000,
          stockQuantity: 10.0,
        ),
      );

      // Record Stock In (+15 units)
      await inventoryRepo.insert(
        InventoryTransactionModel(
          userId: testUserId,
          productId: prodId,
          transactionType: 'STOCK_IN',
          quantity: 15.0,
          unitCostCents: 1200,
          note: 'Restock shipment',
        ),
      );

      var updated = await productRepo.getById(testUserId, prodId);
      expect(updated!.stockQuantity, equals(25.0));

      // Record Stock Out (-5 units)
      await inventoryRepo.insert(
        InventoryTransactionModel(
          userId: testUserId,
          productId: prodId,
          transactionType: 'STOCK_OUT',
          quantity: 5.0,
          note: 'Damage write-off',
        ),
      );

      updated = await productRepo.getById(testUserId, prodId);
      expect(updated!.stockQuantity, equals(20.0));

      // Clean up
      await productRepo.delete(testUserId, prodId);
    });
  });
}
