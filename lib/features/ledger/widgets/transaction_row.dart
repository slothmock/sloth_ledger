import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sloth_budget/domain/transactions/transaction.dart';
import 'package:sloth_budget/features/ledger/modals/transaction_detail_modal.dart';
import 'package:sloth_budget/features/ledger/state/account_state.dart';
import 'package:sloth_budget/features/ledger/state/transaction_state.dart';
import 'package:sloth_budget/features/ledger/utils/relative_labels.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.txn,
    required this.currencySymbol,
    this.showAccountName = true,
    this.dense = false,
    this.enableDelete = true,
  });

  final SlothTransaction txn;
  final String currencySymbol;

  final bool showAccountName;
  final bool dense;
  final bool enableDelete;

  @override
  Widget build(BuildContext context) {
    final accountState = context.watch<AccountState>();
    final accountName =
        accountState.byId(txn.accountId)?.name ?? 'Account ${txn.accountId}';

    final dateStr = relativeDateTimeLabel(txn.date);

    final isTransfer = txn.isTransfer || txn.category == 'Transfer';
    final isExpense = txn.isExpense;

    final icon = isTransfer
        ? Icons.swap_horiz
        : (isExpense ? Icons.arrow_upward : Icons.arrow_downward);

    final iconColor = isTransfer
        ? Colors.blueGrey
        : (isExpense ? Colors.red : Colors.green);

    final amountColor = isTransfer
        ? Colors.blueGrey
        : (isExpense ? Colors.red : Colors.green);

    final merchant = txn.merchant?.trim();
    final title = isTransfer
        ? ((txn.merchant?.trim().isNotEmpty ?? false)
              ? txn.merchant!.trim()
              : 'Transfer')
        : ((merchant != null && merchant.isNotEmpty) ? merchant : txn.category);

    // Subtitle line 1: category + account + relative datetime
    final subtitleLine1Parts = <String>[
      dateStr,
      if (showAccountName) accountName,
      if (!isTransfer) txn.category,
    ];
    final subtitleLine1 = subtitleLine1Parts.join(' • ');

    // Subtitle line 2:
    // - transfers: collapsed transfer puts "From → To" in notes
    // - normal: show notes if present
    final notes = txn.notes?.trim();
    final subtitleLine2 = (notes != null && notes.isNotEmpty) ? notes : null;

    return ListTile(
      dense: dense,
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 1 : 2,
      ),
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitleLine1, style: const TextStyle(fontSize: 13)),
          if (subtitleLine2 != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitleLine2,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: Text(
        '$currencySymbol${txn.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: dense ? 12.5 : 14.0,
          fontWeight: FontWeight.w600,
          color: amountColor,
        ),
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          builder: (_) => TransactionDetailModal(txn: txn, hostContext: context),
        );
      },
      onLongPress: enableDelete
          ? () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete transaction?'),
                  content: const Text(
                    'This action can be undone for a short time.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<TransactionState>().deleteWithUndo(
                          context,
                          txn,
                        );
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
    );
  }
}
