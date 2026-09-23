import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_business_manager/core/theme/app_theme.dart';
import 'package:small_business_manager/data/database/database_helper.dart';
import 'package:small_business_manager/data/repositories/user_repository.dart';
import 'package:small_business_manager/data/repositories/inventory_repository.dart';
import 'package:small_business_manager/data/services/auth_service.dart';
import 'package:small_business_manager/data/services/inventory_service.dart';
import 'package:small_business_manager/presentation/providers/auth_provider.dart';
import 'package:small_business_manager/presentation/providers/inventory_provider.dart';
import 'package:small_business_manager/presentation/screens/main_navigation_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late UserRepository userRepo;
  late AuthService authService;
  late AuthProvider authProvider;

  late InventoryRepository inventoryRepo;
  late InventoryService inventoryService;
  late InventoryProvider inventoryProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dbHelper = DatabaseHelper.forTesting(path: inMemoryDatabasePath);
    userRepo = UserRepository(dbHelper: dbHelper);
    authService = AuthService(userRepo: userRepo);
    inventoryRepo = InventoryRepository(dbHelper: dbHelper);
    inventoryService = InventoryService(
      dbHelper: dbHelper,
      inventoryRepo: inventoryRepo,
    );
    authProvider = AuthProvider(authService: authService);
    inventoryProvider = InventoryProvider(inventoryService: inventoryService);

    // Register a test user
    await authService.register(
      name: 'Business Owner',
      usernameOrEmail: 'owner@test.com',
      password: 'password123',
    );
    await authProvider.checkSession();
  });

  tearDown(() async {
    await dbHelper.deleteDb();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<InventoryProvider>.value(value: inventoryProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }

  testWidgets('MainNavigationScreen renders Dashboard by default with 5 bottom tabs', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Dashboard is visible
    expect(find.text("Today's Sales"), findsWidgets);
    expect(find.text('Current Profit'), findsOneWidget);
    expect(find.text('Current Costs'), findsOneWidget);
    expect(find.text('Current Inventory'), findsOneWidget);
    expect(find.text('Outstanding Debt'), findsOneWidget);
    expect(find.text('Active Debtors'), findsOneWidget);
    expect(find.text('Low Stock Alert'), findsOneWidget);

    // Verify Bottom Navigation Bar Destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Dashboard'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Sales'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Inventory'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Debts'), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Reports'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between Sales, Inventory, Debts, and Reports', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Sales Tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Sales'));
    await tester.pumpAndSettle();
    expect(find.text('Sales Management'), findsOneWidget);
    expect(find.text("Today's Sales"), findsWidgets);
    expect(find.text('Sales History'), findsOneWidget);

    // Tap Inventory Tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Inventory'));
    await tester.pumpAndSettle();
    expect(find.text('Inventory Management'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Restock'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Tap Debts Tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Debts'));
    await tester.pumpAndSettle();
    expect(find.text('Debts & Receivables'), findsOneWidget);
    expect(find.text('Debtors'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);

    // Tap Reports Tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Sales Report'), findsWidgets);
    expect(find.text('Cost Report'), findsWidgets);
    expect(find.text('Profit Report'), findsWidgets);
    expect(find.text('Comparison'), findsOneWidget);
  });
}
