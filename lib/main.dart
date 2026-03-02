import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sloth_budget/app/bootstrapbill/startup_state.dart';
import 'package:sloth_budget/app/strings/app_strings.dart';
import 'package:sloth_budget/data/repositories/account_repository.dart';
import 'package:sloth_budget/data/repositories/app_reset_repository.dart';
import 'package:sloth_budget/data/repositories/balance_repository.dart';
import 'package:sloth_budget/data/repositories/category_repository.dart';
import 'package:sloth_budget/data/repositories/settings_repository.dart';
import 'package:sloth_budget/data/repositories/subscriptions_repository.dart';
import 'package:sloth_budget/data/repositories/transaction_repository.dart';

import 'package:sloth_budget/app/app.dart';


import 'package:sloth_budget/features/ledger/state/account_state.dart';
import 'package:sloth_budget/features/ledger/state/balance_state.dart';
import 'package:sloth_budget/features/ledger/state/transaction_state.dart';
import 'package:sloth_budget/app/state/category_state.dart';
import 'package:sloth_budget/app/state/settings_state.dart';
import 'package:sloth_budget/app/state/app_reset_state.dart';

import 'features/subscriptions/subscriptions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final balanceRepo = BalanceRepository();
  final accountRepo = AccountRepository();
  final txnRepo = TransactionRepository();
  final subRepo = SubscriptionRepository();
  final categoryRepo = CategoryRepository();
  final settingsRepo = SettingsRepository();
  final appResetRepo = AppResetRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BalanceState(balanceRepo)),
        ChangeNotifierProxyProvider<BalanceState, AccountState>(
          create: (context) => AccountState(accountRepo, context.read<BalanceState>()),
          update: (context, balances, prev) {
            final state = prev ?? AccountState(accountRepo, balances);
            state.setBalances(balances);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<BalanceState, TransactionState>(
          create: (context) => TransactionState(txnRepo, context.read<BalanceState>()),
          update: (context, balances, prev) {
            final state = prev ?? TransactionState(txnRepo, balances);
            state.setBalances(balances);
            return state;
          },
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionState(subRepo)),
        ChangeNotifierProvider(create: (_) => CategoryState(categoryRepo)),
        ChangeNotifierProvider(create: (_) => SettingsState(settingsRepo)),
        ChangeNotifierProvider(create: (_) => StartupState()),

        ChangeNotifierProxyProvider6<
            AccountState,
            TransactionState,
            CategoryState,
            SettingsState,
            BalanceState,
            SubscriptionState,
            AppResetState>(
          create: (_) => AppResetState(appResetRepo),
          update: (_, accounts, txns, cats, settings, balances, subs, resetState) {
            final state = resetState ?? AppResetState(appResetRepo);
            state.setDeps(
              accounts: accounts,
              txns: txns,
              categories: cats,
              settings: settings,
              balances: balances,
              subs: subs,
            );
            return state;
          },
        ),
      ],
      child: const SlothBudgetRoot(),
    ),
  );
}

class SlothBudgetRoot extends StatefulWidget {
  const SlothBudgetRoot({super.key});

  @override
  State<SlothBudgetRoot> createState() => _SlothBudgetRootState();
}

class _SlothBudgetRootState extends State<SlothBudgetRoot> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    context.read<StartupState>().start(
      balances: context.read<BalanceState>(),
      accounts: context.read<AccountState>(),
      txns: context.read<TransactionState>(),
      subs: context.read<SubscriptionState>(),
      cats: context.read<CategoryState>(),
      settings: context.read<SettingsState>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<StartupState, bool>((s) => s.ready);
    final error = context.select<StartupState, Object?>((s) => s.error);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: error != null
          ? _StartupErrorScreen(error: error)
          : (ready ? const SlothBudgetApp() : const _SplashScreen()),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final Object error;
  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Startup failed: $error'),
      ),
    );
  }
}
