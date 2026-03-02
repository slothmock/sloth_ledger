import 'package:sqflite/sqflite.dart';
import 'package:sloth_budget/data/db/db_service.dart';
import 'package:sloth_budget/domain/accounts/account_enums.dart';

class AppResetRepository {
  AppResetRepository({DBService? db}) : _db = db ?? DBService();
  final DBService _db;


  Future<void> resetApp() async {
    final database = await _db.db;

    await database.transaction((txn) async {
      // Clear data
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('settings');
      await txn.delete('accounts');
      await txn.delete('subscriptions');

      // Reseed default settings
      await txn.insert(
        'settings',
        {'key': 'currency_code', 'value': 'GBP'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'settings',
        {'key': 'currency_symbol', 'value': '£'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Default account
      await txn.insert(
        'accounts',
        {
          'name': 'Cash',
          'category': AccountCategory.fiat.dbValue,
          'type': AccountType.cash.dbValue,
          'currency': 'GBP',
          'opening_balance': 0.0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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
        final row = <String, Object?>{'name': defaultCategories[i]};
        row['sort_order'] = i;

        await txn.insert(
          'categories',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
