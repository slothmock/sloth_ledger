import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sloth_budget/app/bootstrapbill/startup_provider.dart';

import 'package:sloth_budget/app/screens/home_screen.dart';
import 'package:sloth_budget/app/widgets/add_account_modal.dart';
import 'package:sloth_budget/app/widgets/bottom_nav_bar.dart';
import 'package:sloth_budget/features/ledger/ledger.dart';

import 'package:sloth_budget/features/subscriptions/screens/subscriptions_screen.dart';
import 'package:sloth_budget/features/subscriptions/widgets/add_subscription_modal.dart';

class SlothBudgetApp extends ConsumerStatefulWidget {
  const SlothBudgetApp({super.key});

  @override
  SlothBudgetAppState createState() => SlothBudgetAppState();
}

class SlothBudgetAppState extends ConsumerState<SlothBudgetApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    SubscriptionsScreen(),
  ];

  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddTransactionModal() async {
    final accountState = ref.read(accountStateProvider);
    final categoryState = ref.read(categoryStateProvider);

    if (accountState.accounts.isEmpty) {
      await accountState.load(force: true);
    }
    if (categoryState.categories.isEmpty) {
      await categoryState.load(force: true);
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      builder: (_) => const AddTransactionModal(),
    );
  }

  Future<void> _openAddSubscriptionModal() async {
    final accountState = ref.read(accountStateProvider);

    if (accountState.accounts.isEmpty) {
      await accountState.load(force: true);
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      builder: (_) => const AddSubscriptionModal(),
    );
  }

  Future<void> _openAddAccountModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      builder: (_) => const AddAccountModal(),
    );
  }

  FloatingActionButton? _fabForIndex() {
    switch (_currentIndex) {
      case 0: // Home
      case 1: // Ledger/Transactions
        return FloatingActionButton(
          heroTag: 'fab-add-transaction',
          onPressed: _openAddTransactionModal,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(eccentricity: 0.5),
          child: const Icon(Icons.add),
        );
      case 2: // Accounts
        return FloatingActionButton(
          heroTag: 'fab-add-account',
          onPressed: _openAddAccountModal,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(eccentricity: 0.5),
          child: const Icon(Icons.add),
        );
      case 3: // Subscriptions
        return FloatingActionButton(
          heroTag: 'fab-add-subscription',
          onPressed: _openAddSubscriptionModal,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(eccentricity: 0.5),
          child: const Icon(Icons.add),
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
      floatingActionButton: _fabForIndex(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
