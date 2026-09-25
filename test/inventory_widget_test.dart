import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_business_manager/core/theme/app_theme.dart';
import 'package:small_business_manager/data/database/database_helper.dart';
import 'package:small_business_manager/data/models/product_model.dart';
import 'package:small_business_manager/data/repositories/user_repository.dart';
import 'package:small_business_manager/data/repositories/product_repository.dart';
import 'package:small_business_manager/data/repositories/category_repository.dart';
import 'package:small_business_manager/data/repositories/inventory_repository.dart';
import 'package:small_business_manager/data/services/auth_service.dart';
import 'package:small_business_manager/data/services/inventory_service.dart';
import 'package:small_business_manager/presentation/providers/auth_provider.dart';
import 'package:small_business_manager/presentation/providers/inventory_provider.dart';
import 'package:small_business_manager/presentation/screens/inventory/inventory_screen.dart';
import 'package:small_business_manager/presentation/screens/inventory/add_product_screen.dart';
import 'package:small_business_manager/presentation/screens/inventory/restock_screen.dart';

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

  late AuthProvider authProvider;
  late InventoryProvider inventoryProvider;

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

    authProvider = AuthProvider(authService: authService);
    inventoryProvider = InventoryProvider(inventoryService: inventoryService);

    // Register test user with unique username for isolated test runs
    final uniqueUser = 'owner_${DateTime.now().microsecondsSinceEpoch}@store.com';
    await authProvider.register(
      name: 'Store Owner',
      usernameOrEmail: uniqueUser,
      password: 'password123',
    );
  });

  tearDown(() async {
    await dbHelper.deleteDb();
  });

  Widget createTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<InventoryProvider>.value(value: inventoryProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  testWidgets('AddProductScreen creates a new product and records initial movement', (tester) async {
    expect(authProvider.currentUser, isNotNull, reason: 'Auth user must be logged in');
    expect(authProvider.currentUser?.id, isNotNull);

    await tester.pumpWidget(createTestApp(const AddProductScreen()));
    await tester.pumpAndSettle();

    // Fill form using exact labelText predicates with ensureVisible
    Finder fieldByLabel(String labelPrefix) {
      return find.byWidgetPredicate((w) => w is TextField && (w.decoration?.labelText?.startsWith(labelPrefix) ?? false));
    }

    final nameField = fieldByLabel('Product Name');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Matcha Green Tea 100g');

    final costField = fieldByLabel('Cost Price');
    await tester.ensureVisible(costField);
    await tester.enterText(costField, '120.00');

    final sellField = fieldByLabel('Selling Price');
    await tester.ensureVisible(sellField);
    await tester.enterText(sellField, '200.00');

    final stockField = fieldByLabel('Initial Opening Stock');
    await tester.ensureVisible(stockField);
    await tester.enterText(stockField, '50');

    final minStockField = fieldByLabel('Low Stock Alert Threshold');
    await tester.ensureVisible(minStockField);
    await tester.enterText(minStockField, '10');
    await tester.pumpAndSettle();

    // Scroll down to reveal submit button
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    // Submit
    final submitBtn = find.widgetWithText(FilledButton, 'Create Product & Record Stock');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify product added in provider
    expect(inventoryProvider.products.length, equals(1));
    expect(inventoryProvider.products.first.name, equals('Matcha Green Tea 100g'));
    expect(inventoryProvider.products.first.stockQuantity, equals(50.0));
    expect(inventoryProvider.transactions.length, equals(1));
    expect(inventoryProvider.transactions.first.transactionType, equals('STOCK_IN'));
  });

  testWidgets('RestockScreen restocks an existing product and logs STOCK_IN', (tester) async {
    // First create a product
    final product = await inventoryService.addProduct(
      product: ProductModel(
        userId: authProvider.currentUser!.id!,
        name: 'Whole Milk 1L',
        buyPriceCents: 5000,
        sellPriceCents: 8000,
        unit: 'bottle',
        minStockAlert: 5.0,
      ),
      initialStock: 10.0,
    );
    await inventoryProvider.loadData(authProvider.currentUser!.id!);

    await tester.pumpWidget(createTestApp(RestockScreen(initialProduct: product)));
    await tester.pumpAndSettle();

    Finder fieldByLabel(String labelPrefix) {
      return find.byWidgetPredicate((w) => w is TextField && (w.decoration?.labelText?.startsWith(labelPrefix) ?? false));
    }

    // Enter quantity to add
    final qtyField = fieldByLabel('Quantity to Add');
    await tester.ensureVisible(qtyField);
    await tester.enterText(qtyField, '20');

    final supplierField = fieldByLabel('Supplier');
    await tester.ensureVisible(supplierField);
    await tester.enterText(supplierField, 'PO-882');
    await tester.pumpAndSettle();

    // Scroll down to reveal restock button
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Submit Restock
    final restockBtn = find.widgetWithText(FilledButton, 'Confirm Restock & Record Movement');
    await tester.ensureVisible(restockBtn);
    await tester.pumpAndSettle();
    await tester.tap(restockBtn);
    await tester.pumpAndSettle();

    // Verify stock is now 10 + 20 = 30
    final p = inventoryProvider.products.firstWhere((item) => item.name == 'Whole Milk 1L');
    expect(p.stockQuantity, equals(30.0));
    expect(inventoryProvider.transactions.length, equals(2));
  });

  testWidgets('InventoryScreen tabs and stock filters function properly', (tester) async {
    // Populate sample products
    final userId = authProvider.currentUser!.id!;
    await inventoryService.addProduct(
      product: ProductModel(
        userId: userId,
        name: 'Product High Stock',
        buyPriceCents: 1000,
        sellPriceCents: 2000,
        minStockAlert: 5.0,
      ),
      initialStock: 25.0,
    );
    await inventoryService.addProduct(
      product: ProductModel(
        userId: userId,
        name: 'Product Low Stock',
        buyPriceCents: 1000,
        sellPriceCents: 2000,
        minStockAlert: 10.0,
      ),
      initialStock: 2.0,
    );
    await inventoryProvider.loadData(userId);

    await tester.pumpWidget(createTestApp(const InventoryScreen()));
    await tester.pumpAndSettle();

    // Verify both products present
    expect(find.text('Product High Stock'), findsOneWidget);
    expect(find.text('Product Low Stock'), findsOneWidget);

    // Tap Low Stock filter
    await tester.tap(find.textContaining('Low Stock (1)'));
    await tester.pumpAndSettle();

    // Only Low stock product shown
    expect(find.text('Product Low Stock'), findsOneWidget);
    expect(find.text('Product High Stock'), findsNothing);

    // Switch to History Tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Movement Audit Log'), findsOneWidget);
  });
}
