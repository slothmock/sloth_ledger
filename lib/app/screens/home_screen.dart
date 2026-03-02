import 'package:flutter/material.dart';
import 'package:flutter_donation_buttons/donationButtons/ko-fiButton.dart';
import 'package:flutter_donation_buttons/flutter_donation_buttons.dart';
import 'package:provider/provider.dart';

import 'package:sloth_budget/app/screens/settings_screen.dart';
import 'package:sloth_budget/app/state/settings_state.dart';
import 'package:sloth_budget/app/strings/app_strings.dart';
import 'package:sloth_budget/app/widgets/balance_card.dart';
import 'package:sloth_budget/app/widgets/info_toast.dart';

import 'package:sloth_budget/domain/accounts/account_enums.dart';

import 'package:sloth_budget/features/ledger/ledger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionState>().ensureMinLoaded(10);
      context.read<BalanceState>().load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final txnState = context.read<TransactionState>();
      await txnState.ensureCoversMonth(DateTime.now());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<TransactionState>().refreshAll(),
      context.read<SettingsState>().load(force: true),
      context.read<BalanceState>().load(force: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final accountState = context.watch<AccountState>();
    final txnState = context.watch<TransactionState>();
    final settingsState = context.watch<SettingsState>();
    final balances = context.watch<BalanceState>();

    final settings = settingsState.settings;
    final recentTxns = txnState.recent(limit: 5);
    final collapsedRecent = collapseTransfers(recentTxns, accountState);

    final cash = balances.totalFor(
      currencyCode: settings.currencyCode,
      category: AccountCategory.fiat,
    );
    final investments = balances.totalFor(
      currencyCode: settings.currencyCode,
      category: AccountCategory.investments,
    );

    final netWorth = cash + investments;

    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.only(top: 64),
      top: true,
      bottom: false,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: true,
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Balance row (simple, clean)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: BalanceCard(
                            label: AppStrings.cashTypeLabel,
                            amount: cash,
                            currencySymbol: settings.currencySymbol,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: BalanceCard(
                            label: AppStrings.netWorthLabel,
                            amount: netWorth,
                            currencySymbol: settings.currencySymbol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtle divider to separate "summary" from content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      height: 0.5,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.24),
                    ),
                  ),
                ),
                // Recent transactions card
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.recentTransactions,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (!txnState.allLoaded && txnState.loading)
                              const SizedBox(
                                height: 140,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (txnState.errorMessage != null &&
                                recentTxns.isEmpty)
                              Text(
                                txnState.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              )
                            else if (recentTxns.isEmpty)
                              const SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    AppStrings.noRecentTransactionsTitle,
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: collapsedRecent
                                    .map(
                                      (txn) => TransactionRow(
                                        txn: txn,
                                        currencySymbol: settings.currencySymbol,
                                        showAccountName: false,
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        KofiButton(text: AppStrings.supportSlothKofi, kofiName: "slothmock", kofiColor: KofiColor.Orange, onDonation: () => CustomInfoToast.show(context, message: AppStrings.thanksForSupport),),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
