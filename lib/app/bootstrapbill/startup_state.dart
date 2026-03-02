import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sloth_budget/app/logging/app_logger.dart';
import 'package:sloth_budget/app/state/category_state.dart';
import 'package:sloth_budget/app/state/settings_state.dart';
import 'package:sloth_budget/data/db/db_service.dart';
import 'package:sloth_budget/features/ledger/ledger.dart';
import 'package:sloth_budget/features/subscriptions/subscriptions.dart';

class StartupState extends ChangeNotifier {
  bool _ready = false;
  bool get ready => _ready;

  Object? _error;
  Object? get error => _error;

  bool _started = false;

  Future<void> start({
    required BalanceState balances,
    required AccountState accounts,
    required TransactionState txns,
    required SubscriptionState subs,
    required CategoryState cats,
    required SettingsState settings,
  }) async {
    if (_started) return;
    _started = true;

    try {
      // Move your "main()" awaits here so UI can render first.
      final info = await PackageInfo.fromPlatform();
      log.i('Sloth Budget v${info.version}+${info.buildNumber} starting');

      await DBService().db;
      final dbVersion = DBService().getDbVersion();
      log.i('DB version: $dbVersion');

      // Kick off your existing loads (in a safe order if needed)
      await balances.load();
      await Future.wait([
        accounts.load(),
        txns.loadAll(),
        subs.load(),
        cats.load(),
        settings.load(),
      ]);

      _ready = true;
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }
}