import 'package:sloth_ledger/domain/accounts/account_enums.dart';
import 'package:sloth_ledger/domain/app_settings/app_settings.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sloth_ledger/domain/transactions/transaction.dart';

class DBService {
  // Singleton
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static const int schemaVersion = 1;
  int getDbVersion() => schemaVersion;

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sloth_ledger.db');

    return await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        merchant TEXT,
        date INTEGER NOT NULL,
        account_id INTEGER NOT NULL REFERENCES accounts(id),
        transfer_group_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
        CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

    await _createSubscriptionsTable(db);
    await _createSubsEventsTable(db);

    // Seed defaults
    await db.insert('settings', {'key': 'currency_code', 'value': 'GBP'});
    await db.insert('settings', {'key': 'currency_symbol', 'value': '£'});

    await db.insert('accounts', {
      'name': 'Cash',
      'category': 'fiat',
      'type': 'cash',
      'currency': 'GBP',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    const defaultCategories = [
      'Salary',
      'Rent',
      'Utilities',
      'Groceries',
      'Investment',
      'Entertainment',
      'Travel',
      'Subscriptions',
    ];

    for (var i = 0; i < defaultCategories.length; i++) {
      await db.insert('categories', {
        'name': defaultCategories[i],
        'sort_order': i,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    throw Exception('DB upgrades not yet implemented. Old version: $oldVersion, new version: $newVersion');  
  }

  Future<void> _createSubscriptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        interval TEXT NOT NULL,
        next_due INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_next_due ON subscriptions(next_due);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON subscriptions(is_active);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_account ON subscriptions(account_id);',
    );
  }

  Future<void> _createSubsEventsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS subscription_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subscription_id INTEGER NOT NULL,
      kind TEXT NOT NULL,
      amount REAL,
      date INTEGER NOT NULL,
      due_date INTEGER,
      notes TEXT,
      txn_id INTEGER
    );
  ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_subscription_events_subscription_id
      ON subscription_events(subscription_id);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_subscription_events_date
      ON subscription_events(date);
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS ux_subscription_paid_cycle
      ON subscription_events(subscription_id, kind, due_date);
    ''');
  }

  Future<void> runInTransaction(
    Future<void> Function(Transaction txn) action,
  ) async {
    final database = await db;
    await database.transaction(action);
  }

  // =========================
  // ACCOUNTS
  // =========================

  Future<int> insertAccount({
    required String name,
    required String category,
    required String type,
    required String currency,
    required int createdAtMillis,
    double openingBalance = 0,
  }) async {
    final database = await db;
    return database.insert('accounts', {
      'name': name,
      'category': category,
      'type': type,
      'currency': currency,
      'opening_balance': openingBalance,
      'created_at': createdAtMillis,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required String category,
    required String type,
    required String currency,
    required double openingBalance,
  }) async {
    final database = await db;
    await database.update(
      'accounts',
      {
        'name': name,
        'category': category,
        'type': type,
        'currency': currency,
        'opening_balance': openingBalance,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final database = await db;
    return database.query(
      'accounts',
      columns: [
        'id',
        'name',
        'category',
        'type',
        'currency',
        'opening_balance',
        'created_at',
      ],
      orderBy: 'name',
    );
  }

  Future<int> deleteAccount(int id) async {
    final database = await db;
    return await database.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // TRANSACTIONS
  // =========================

  Future<int> insertTransaction({
    required double amount,
    required String category,
    String? notes,
    String? merchant,
    required int dateMillis,
    required int accountId,
    String? transferGroupId,
  }) async {
    final database = await db;
    return await database.insert('transactions', {
      'amount': amount,
      'category': category,
      'notes': notes,
      'merchant': merchant,
      'date': dateMillis,
      'account_id': accountId,
      'transfer_group_id': transferGroupId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SlothTransaction>> getTransactions({int? limit}) async {
    final database = await db;
    final result = await database.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );

    return result.map((row) => SlothTransaction.fromMap(row)).toList();
  }

  Future<List<SlothTransaction>> getTransactionsPaged({
    required int limit,
    required int offset,
  }) async {
    final database = await db;
    final result = await database.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((row) => SlothTransaction.fromMap(row)).toList();
  }

  Future<List<SlothTransaction>> getExpenses({int? limit}) async {
    final database = await db;
    final result = await database.query(
      'transactions',
      where: 'amount < 0',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((row) => SlothTransaction.fromMap(row)).toList();
  }

  Future<List<SlothTransaction>> getIncome({int? limit}) async {
    final database = await db;
    final result = await database.query(
      'transactions',
      where: 'amount >= 0',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((row) => SlothTransaction.fromMap(row)).toList();
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> fields) async {
    final database = await db;
    return await database.update(
      'transactions',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final database = await db;
    return await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> getTransactionAmounts() async {
    final database = await db;
    return database.query('transactions', columns: ['account_id', 'amount']);
  }

  // =========================
  // CATEGORIES
  // =========================

  Future<int> insertCategory(String name) async {
    final database = await db;
    return await database.insert('categories', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories() async {
    final database = await db;
    final result = await database.query(
      'categories',
      orderBy: 'sort_order ASC',
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<int> countTransactionsForCategory(String name) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as c FROM transactions WHERE category = ?',
      [name],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> renameCategory(String from, String to) async {
    final database = await db;

    await database.transaction((txn) async {
      // Update categories table
      await txn.update(
        'categories',
        {'name': to},
        where: 'name = ?',
        whereArgs: [from],
      );

      // Update all transactions that reference the old category string
      await txn.update(
        'transactions',
        {'category': to},
        where: 'category = ?',
        whereArgs: [from],
      );
    });
  }

  Future<void> updateCategoryOrder(List<String> orderedNames) async {
    final database = await db;
    final batch = database.batch();

    for (var i = 0; i < orderedNames.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'name = ?',
        whereArgs: [orderedNames[i]],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<int> deleteCategoryByName(String name) async {
    final database = await db;
    return database.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // =========================
  // TRANSFER HELPERS
  // =========================

  Future<List<SlothTransaction>> getTransactionsByTransferGroupId(
    String transferGroupId,
  ) async {
    final database = await db;

    final rows = await database.query(
      'transactions',
      where: 'transfer_group_id = ?',
      whereArgs: [transferGroupId],
      orderBy: 'date DESC',
    );

    return rows.map((r) => SlothTransaction.fromMap(r)).toList();
  }

  Future<int> deleteTransactionsByTransferGroupId(
    String transferGroupId,
  ) async {
    final database = await db;

    return database.delete(
      'transactions',
      where: 'transfer_group_id = ?',
      whereArgs: [transferGroupId],
    );
  }

  // =========================
  // SUBSCRIPTIONS
  // =========================

  Future<int> insertSubscription({
    required String name,
    required double amount,
    required String currency,
    required String interval,
    required int nextDueMillis,
    required int accountId,
    bool isActive = true,
  }) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;

    return database.insert('subscriptions', {
      'name': name,
      'amount': amount,
      'currency': currency,
      'interval': interval,
      'next_due': nextDueMillis,
      'account_id': accountId,
      'is_active': isActive ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, Object?>>> getSubscriptions({
    bool activeOnly = true,
  }) async {
    final database = await db;

    return database.query(
      'subscriptions',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'next_due ASC, name COLLATE NOCASE ASC',
    );
  }

  Future<List<Map<String, Object?>>> getUpcomingSubscriptions({
    required int fromMillis,
    required int toMillis,
    bool activeOnly = true,
  }) async {
    final database = await db;

    final where = <String>[
      'next_due >= ?',
      'next_due <= ?',
      if (activeOnly) 'is_active = 1',
    ].join(' AND ');

    final args = [fromMillis, toMillis];

    return database.query(
      'subscriptions',
      where: where,
      whereArgs: args,
      orderBy: 'next_due ASC',
    );
  }

  Future<int> updateSubscription(int id, Map<String, Object?> fields) async {
    final database = await db;
    fields['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    return database.update(
      'subscriptions',
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final database = await db;
    return database.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setSubscriptionActive(int id, bool active) async {
    return updateSubscription(id, {'is_active': active ? 1 : 0});
  }

  // =========================
  // SETTINGS
  // =========================

  Future<String?> getSetting(String key) async {
    final database = await db;
    final result = await database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppSettings> getAppSettings() async {
    final code = await getSetting('currency_code');
    final symbol = await getSetting('currency_symbol');

    return AppSettings(
      currencyCode: code ?? AppSettings.defaults.currencyCode,
      currencySymbol: symbol ?? AppSettings.defaults.currencySymbol,
    );
  }

  Future<void> setCurrency({
    required String code,
    required String symbol,
  }) async {
    await setSetting('currency_code', code);
    await setSetting('currency_symbol', symbol);
  }

  Future<void> deleteAllTransactions() async {
    final database = await db;
    await database.delete('transactions');
  }

  Future<void> resetApp() async {
    final database = await db;

    await database.delete('transactions');
    await database.delete('categories');
    await database.delete('settings');
    await database.delete('accounts');

    // re-seed defaults
    await setCurrency(code: 'GBP', symbol: '£');

    await insertAccount(
      name: 'Cash',
      category: AccountCategory.fiat.name,
      type: AccountType.cash.name,
      currency: 'GBP',
      openingBalance: 0.0,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    const defaultCategories = [
      'Groceries',
      'Rent',
      'Utilities',
      'Salary',
      'Investment',
      'Entertainment',
      'Travel',
    ];
    for (var cat in defaultCategories) {
      await insertCategory(cat);
    }
  }
}
