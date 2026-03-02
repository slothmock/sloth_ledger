import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sloth_budget/domain/transactions/transaction.dart';
import 'package:sloth_budget/features/ledger/modals/add_transaction_modal.dart';
import 'package:sloth_budget/features/ledger/state/account_state.dart';
import 'package:sloth_budget/app/state/settings_state.dart';
import 'package:sloth_budget/features/ledger/state/transaction_state.dart';

class TransactionDetailModal extends StatelessWidget {
  const TransactionDetailModal({
    super.key,
    required this.txn,
    required this.hostContext,
  });
  final SlothTransaction txn;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final title = (txn.merchant?.trim().isNotEmpty ?? false)
        ? txn.merchant!.trim()
        : txn.category;
    final symbol = context.watch<SettingsState>().settings.currencySymbol;
    final accountName =
        context.watch<AccountState>().byId(txn.accountId)?.name ??
        'Account ${txn.accountId}';

    final dt = DateFormat.yMMMMd().add_jm().format(txn.date);
    final isExpense = txn.isExpense;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Row(
                children: [
                  Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$symbol${txn.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),

              _kv('Account', accountName),
              _kv('Date', dt),
              if ((txn.notes ?? '').trim().isNotEmpty)
                _kv('Notes', txn.notes!.trim()),
              if (txn.isTransfer) _kv('Transfer', 'Yes'),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Edit'),
                      onPressed: () async {
                        Navigator.pop(context);

                        await showModalBottomSheet(
                          context: hostContext,
                          isScrollControlled: true,
                          useSafeArea: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          builder: (_) => AddTransactionModal(transaction: txn),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () async {

                        if (txn.id == null) return;

                        await hostContext
                            .read<TransactionState>()
                            .deleteWithUndo(hostContext, txn);
                            
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(k, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
