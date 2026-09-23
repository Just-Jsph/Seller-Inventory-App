import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_migrations.dart';

/// Core Database Helper managing SQLite connection, initialization, and lifecycle.
class DatabaseHelper {
  static const String databaseName = 'small_business_manager.db';

  // Singleton instance
  static DatabaseHelper? _instance;
  static Database? _database;

  // Optional override path (used in tests for in-memory databases)
  final String? _overridePath;

  DatabaseHelper._internal({this._overridePath});

  /// Default singleton for production use
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Test-only factory: creates an isolated, non-singleton instance with a custom path.
  /// Use [inMemoryDatabasePath] from sqflite for pure in-memory databases.
  factory DatabaseHelper.forTesting({required String path}) {
    return DatabaseHelper._internal(overridePath: path);
  }

  /// Get active database instance or initialize if needed
  Future<Database> get database async {
    if (_database != null && _database!.isOpen && _overridePath == null) {
      return _database!;
    }
    final db = await _initDatabase();
    if (_overridePath == null) {
      _database = db;
    }
    return db;
  }

  /// Initialize SQLite database with foreign keys enabled
  Future<Database> _initDatabase() async {
    final String dbPath = _overridePath ?? join(await getDatabasesPath(), databaseName);

    return await openDatabase(
      dbPath,
      version: DatabaseMigrations.currentVersion,
      onConfigure: _onConfigure,
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
    );
  }

  /// Enforce SQLite Foreign Key constraints
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Close database connection
  Future<void> close() async {
    if (_overridePath == null) {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
    }
  }

  /// Delete the database file (for test teardown or data reset).
  Future<void> deleteDb({String? customPath}) async {
    await close();
    final String dbPath = customPath ?? _overridePath ?? join(await getDatabasesPath(), databaseName);
    await deleteDatabase(dbPath);
  }
}
