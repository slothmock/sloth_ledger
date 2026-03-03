import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sloth_budget/app/strings/app_strings.dart';
import 'package:sloth_budget/app/widgets/info_toast.dart';

import 'package:sloth_budget/domain/accounts/account.dart';
import 'package:sloth_budget/features/ledger/screens/account_details_screen.dart';
import 'package:sloth_budget/features/ledger/state/account_state.dart';

import 'package:sloth_budget/features/ledger/state/balance_state.dart';
import 'package:sloth_budget/features/ledger/modals/transfer_modal.dart';
import 'package:sloth_budget/app/widgets/add_account_modal.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _openAccountModal(BuildContext context, {SlothAccount? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => AddAccountModal(account: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.accountsTitle),
      ),
      body: _Body(
        state: state,
        onEdit: (acc) => _openAccountModal(context, account: acc),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onEdit});

  final AccountState state;
  final void Function(SlothAccount acc) onEdit;

  @override
  Widget build(BuildContext context) {
    final balances = context.watch<BalanceState>();

    // First-load spinner only if we have no cached data yet
    if (state.loading && state.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.accounts.isEmpty) {
      return const Center(child: Text(AppStrings.noAccounts));
    }

    return SafeArea(
      child: ListView.builder(
        itemCount: state.accounts.length,
        itemBuilder: (context, index) {
          final acc = state.accounts[index];
          final accountBalance = (acc.id == null)
              ? acc.openingBalance
              : (balances.accountBalances[acc.id!] ?? acc.openingBalance);
          return ListTile(
            title: Text(
              '${acc.name}: ${accountBalance.toStringAsFixed(2)} ${acc.currency}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: accountBalance < 0 ? Colors.red : null,
              ),
            ),
            subtitle: Text(
              '${acc.categoryLabel} • ${acc.typeLabel}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onEdit(acc),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final msg = await context
                        .read<AccountState>()
                        .deleteWithRules(acc.id!);
                    if (msg != null && context.mounted) {
                      CustomInfoToast.show(context, message: msg);
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountDetailScreen(account: acc),
                ),
              );
            },
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                builder: (_) => TransferModal(fromAccountId: acc.id),
              );
            },
          );
        },
      ),
    );
  }
}
