import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_business_manager/core/utils/password_hasher.dart';
import 'package:small_business_manager/core/utils/validators.dart';
import 'package:small_business_manager/data/database/database_helper.dart';
import 'package:small_business_manager/data/models/product_model.dart';
import 'package:small_business_manager/data/models/category_model.dart';
import 'package:small_business_manager/data/repositories/product_repository.dart';
import 'package:small_business_manager/data/repositories/category_repository.dart';
import 'package:small_business_manager/data/repositories/user_repository.dart';
import 'package:small_business_manager/data/services/auth_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late UserRepository userRepo;
  late AuthService authService;
  late ProductRepository productRepo;
  late CategoryRepository categoryRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Each test gets a fresh in-memory database
    dbHelper = DatabaseHelper.forTesting(path: inMemoryDatabasePath);
    userRepo = UserRepository(dbHelper: dbHelper);
    authService = AuthService(userRepo: userRepo);
    productRepo = ProductRepository(dbHelper: dbHelper);
    categoryRepo = CategoryRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.deleteDb();
  });

  group('Authentication & Security Tests', () {
    test('Password Hasher never stores plaintext and verifies correctly', () {
      const plainPassword = 'SuperSecretPassword123!';
      final hash1 = PasswordHasher.hashPassword(plainPassword);
      final hash2 = PasswordHasher.hashPassword(plainPassword);

      expect(hash1, isNot(equals(plainPassword)));
      expect(hash1, equals(hash2));
      expect(PasswordHasher.verifyPassword(plainPassword, hash1), isTrue);
      expect(PasswordHasher.verifyPassword('WrongPassword', hash1), isFalse);
    });

    test('Validators correctly enforce field rules', () {
      // Name
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('Alice Smith'), isNull);

      // Username / Email
      expect(Validators.validateUsernameOrEmail(''), isNotNull);
      expect(Validators.validateUsernameOrEmail('al'), isNotNull);
      expect(Validators.validateUsernameOrEmail('alice_smith'), isNull);
      expect(Validators.validateUsernameOrEmail('invalid-email@'), isNotNull);
      expect(Validators.validateUsernameOrEmail('alice@example.com'), isNull);

      // Password
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);

      // Confirm Password
      expect(Validators.validateConfirmPassword('123456', 'different'), isNotNull);
      expect(Validators.validateConfirmPassword('123456', '123456'), isNull);
    });

    test('User registration, login, and session persistence lifecycle', () async {
      // 1. Register User 1
      final user1 = await authService.register(
        name: 'John Doe',
        usernameOrEmail: 'johndoe@test.com',
        password: 'password123',
      );

      expect(user1.id, isNotNull);
      expect(user1.name, equals('John Doe'));
      expect(user1.username, equals('johndoe@test.com'));
      expect(user1.passwordHash, isNot(equals('password123')));

      // 2. Prevent Duplicate Registration
      expect(
        () => authService.register(
          name: 'Another John',
          usernameOrEmail: 'johndoe@test.com',
          password: 'password456',
        ),
        throwsA(isA<AuthException>()),
      );

      // 3. Test Active Session Saved
      final activeSession = await authService.getActiveSession();
      expect(activeSession, isNotNull);
      expect(activeSession!.id, equals(user1.id));

      // 4. Logout clears session but keeps user in DB
      await authService.logout();
      expect(await authService.getActiveSession(), isNull);

      // 5. Test Login
      final loggedInUser = await authService.login(
        usernameOrEmail: 'johndoe@test.com',
        password: 'password123',
      );
      expect(loggedInUser.id, equals(user1.id));
      expect(await authService.getActiveSession(), isNotNull);

      // 6. Test Failed Login with Wrong Password
      expect(
        () => authService.login(
          usernameOrEmail: 'johndoe@test.com',
          password: 'wrong_password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Data Isolation: Users cannot see another user\'s business data', () async {
      // Register User A
      final userA = await authService.register(
        name: 'User A',
        usernameOrEmail: 'usera',
        password: 'passwordA',
      );

      // Register User B  (logout A first to re-use service cleanly)
      await authService.logout();
      final userB = await authService.register(
        name: 'User B',
        usernameOrEmail: 'userb',
        password: 'passwordB',
      );

      // User A creates Category and Product
      final catAId = await categoryRepo.insert(
        CategoryModel(userId: userA.id!, name: 'Electronics'),
      );
      final prodAId = await productRepo.insert(
        ProductModel(
          userId: userA.id!,
          categoryId: catAId,
          name: 'Laptop User A',
          buyPriceCents: 50000,
          sellPriceCents: 75000,
          stockQuantity: 5.0,
        ),
      );

      // User B creates Category and Product
      final catBId = await categoryRepo.insert(
        CategoryModel(userId: userB.id!, name: 'Groceries'),
      );
      final prodBId = await productRepo.insert(
        ProductModel(
          userId: userB.id!,
          categoryId: catBId,
          name: 'Apples User B',
          buyPriceCents: 100,
          sellPriceCents: 200,
          stockQuantity: 50.0,
        ),
      );

      // Query User A's products — should see only their own
      final userAProducts = await productRepo.getAll(userA.id!);
      expect(userAProducts.length, equals(1));
      expect(userAProducts.first.name, equals('Laptop User A'));

      // Query User B's products — should see only their own
      final userBProducts = await productRepo.getAll(userB.id!);
      expect(userBProducts.length, equals(1));
      expect(userBProducts.first.name, equals('Apples User B'));

      // User A attempts to get User B's product by ID -> must return null
      final crossQuery = await productRepo.getById(userA.id!, prodBId);
      expect(crossQuery, isNull);

      // User A logs out and logs in again -> business data remains intact
      await authService.logout();
      await authService.login(usernameOrEmail: 'usera', password: 'passwordA');
      final restoredAProducts = await productRepo.getAll(userA.id!);
      expect(restoredAProducts.length, equals(1));
      expect(restoredAProducts.first.id, equals(prodAId));
    });
  });
}
