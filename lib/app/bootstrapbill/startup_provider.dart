import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sloth_budget/app/logging/app_logger.dart';
import 'package:sloth_budget/app/state/app_reset_state.dart';
import 'package:sloth_budget/app/state/category_state.dart';
import 'package:sloth_budget/app/state/settings_state.dart';
import 'package:sloth_budget/data/db/db_service.dart';
import 'package:sloth_budget/data/repositories/account_repository.dart';
import 'package:sloth_budget/data/repositories/app_reset_repository.dart';
import 'package:sloth_budget/data/repositories/balance_repository.dart';
import 'package:sloth_budget/data/repositories/category_repository.dart';
import 'package:sloth_budget/data/repositories/settings_repository.dart';
import 'package:sloth_budget/data/repositories/subscriptions_repository.dart';
import 'package:sloth_budget/data/repositories/transaction_repository.dart';
import 'package:sloth_budget/features/ledger/ledger.dart';
import 'package:sloth_budget/features/subscriptions/subscriptions.dart';

final balanceRepoProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepository();
});
final accountRepoProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});
final txnRepoProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});
final subscriptionRepoProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});
final categoryRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});
final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});
final appResetRepoProvider = Provider<AppResetRepository>((ref) {
  return AppResetRepository();
});
final balanceStateProvider = ChangeNotifierProvider<BalanceState>((ref) {
  return BalanceState(ref.read(balanceRepoProvider));
});
final accountStateProvider = ChangeNotifierProvider<AccountState>((ref) {
  return AccountState(
    ref.read(accountRepoProvider),
    ref.read(balanceStateProvider),
  );
});
final transactionStateProvider = ChangeNotifierProvider<TransactionState>((
  ref,
) {
  return TransactionState(
    ref.read(txnRepoProvider),
    ref.read(balanceStateProvider),
  );
});
final subscriptionStateProvider = ChangeNotifierProvider<SubscriptionState>((
  ref,
) {
  return SubscriptionState(ref.read(subscriptionRepoProvider));
});
final categoryStateProvider = ChangeNotifierProvider<CategoryState>((ref) {
  return CategoryState(ref.read(categoryRepoProvider));
});
final settingsStateProvider = ChangeNotifierProvider<SettingsState>((ref) {
  return SettingsState(ref.read(settingsRepoProvider));
});

final appResetStateProvider = ChangeNotifierProvider<AppResetState>((ref) {
  final state = AppResetState(ref.read(appResetRepoProvider));

  state.setDeps(
    accounts: ref.read(accountStateProvider),
    txns: ref.read(transactionStateProvider),
    categories: ref.read(categoryStateProvider),
    settings: ref.read(settingsStateProvider),
    balances: ref.read(balanceStateProvider),
    subs: ref.read(subscriptionStateProvider),
  );

  return state;
});

final startupProvider = FutureProvider<void>((ref) async {
  final info = await PackageInfo.fromPlatform();
  log.i('Sloth Budget v${info.version}+${info.buildNumber} starting');

  await DBService().db;
  final dbVersion = DBService().getDbVersion();
  log.i('DB version: $dbVersion');

  await ref.read(balanceStateProvider).load();

  await Future.wait([
    ref.read(accountStateProvider).load(),
    ref.read(transactionStateProvider).loadAll(),
    ref.read(subscriptionStateProvider).load(),
    ref.read(categoryStateProvider).load(),
    ref.read(settingsStateProvider).load(),
  ]);
});
