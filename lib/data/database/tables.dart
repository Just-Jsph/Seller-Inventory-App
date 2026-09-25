/// Database Table & Column Name Constants, DDL definitions, and Indexes
class AppTables {
  // Table Names
  static const String users = 'users';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String inventoryTransactions = 'inventory_transactions';
  static const String sales = 'sales';
  static const String saleItems = 'sale_items';
  static const String debts = 'debts';
  static const String debtItems = 'debt_items';
  static const String debtPayments = 'debt_payments';
  static const String expenses = 'expenses';
  static const String settings = 'settings';

  // DDL Scripts with strict per-user foreign key isolation
  static const String createUsersTable = '''
    CREATE TABLE $users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createCategoriesTable = '''
    CREATE TABLE $categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE,
      UNIQUE (user_id, name)
    );
  ''';

  static const String createProductsTable = '''
    CREATE TABLE $products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      category_id INTEGER,
      name TEXT NOT NULL,
      sku TEXT,
      barcode TEXT,
      buy_price_cents INTEGER NOT NULL DEFAULT 0,
      sell_price_cents INTEGER NOT NULL DEFAULT 0,
      stock_quantity REAL NOT NULL DEFAULT 0.0,
      min_stock_alert REAL NOT NULL DEFAULT 5.0,
      unit TEXT NOT NULL DEFAULT 'pcs',
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES $categories (id) ON DELETE SET NULL,
      UNIQUE (user_id, sku),
      UNIQUE (user_id, barcode)
    );
  ''';

  static const String createInventoryTransactionsTable = '''
    CREATE TABLE $inventoryTransactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      transaction_type TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_cost_cents INTEGER,
      note TEXT,
      reference_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $products (id) ON DELETE CASCADE
    );
  ''';

  static const String createSalesTable = '''
    CREATE TABLE $sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      invoice_number TEXT NOT NULL,
      customer_name TEXT,
      customer_phone TEXT,
      total_amount_cents INTEGER NOT NULL DEFAULT 0,
      discount_cents INTEGER NOT NULL DEFAULT 0,
      paid_amount_cents INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'CASH',
      payment_status TEXT NOT NULL DEFAULT 'PAID',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE,
      UNIQUE (user_id, invoice_number)
    );
  ''';

  static const String createSaleItemsTable = '''
    CREATE TABLE $saleItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 1.0,
      unit_price_cents INTEGER NOT NULL DEFAULT 0,
      subtotal_cents INTEGER NOT NULL DEFAULT 0,
      cost_cents INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES $sales (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $products (id) ON DELETE RESTRICT
    );
  ''';

  static const String createDebtsTable = '''
    CREATE TABLE $debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      customer_name TEXT NOT NULL,
      customer_phone TEXT,
      total_amount_cents INTEGER NOT NULL DEFAULT 0,
      paid_amount_cents INTEGER NOT NULL DEFAULT 0,
      interest_rate_percent REAL NOT NULL DEFAULT 0,
      due_date TEXT,
      status TEXT NOT NULL DEFAULT 'UNPAID',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE
    );
  ''';

  static const String createDebtItemsTable = '''
    CREATE TABLE $debtItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debt_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 1.0,
      unit_price_cents INTEGER NOT NULL DEFAULT 0,
      subtotal_cents INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (debt_id) REFERENCES $debts (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $products (id) ON DELETE RESTRICT
    );
  ''';

  static const String createDebtPaymentsTable = '''
    CREATE TABLE $debtPayments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debt_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      amount_cents INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'CASH',
      payment_date TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (debt_id) REFERENCES $debts (id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE
    );
  ''';

  static const String createExpensesTable = '''
    CREATE TABLE $expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      category_id INTEGER,
      title TEXT NOT NULL,
      amount_cents INTEGER NOT NULL DEFAULT 0,
      expense_date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $users (id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES $categories (id) ON DELETE SET NULL
    );
  ''';

  static const String createSettingsTable = '''
    CREATE TABLE $settings (
      user_id INTEGER,
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY (user_id, key)
    );
  ''';

  // Performance Indexes with user_id optimization
  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_products_user ON $products (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_categories_user ON $categories (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_inventory_user ON $inventoryTransactions (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_user ON $sales (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_debts_user ON $debts (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_expenses_user ON $expenses (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON $saleItems (sale_id);',
    'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON $debtPayments (debt_id);',
  ];
}
