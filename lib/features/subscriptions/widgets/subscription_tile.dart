import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sloth_budget/app/utils/currency_formatter.dart';
import 'package:sloth_budget/domain/subscriptions/subscription.dart';

import 'package:sloth_budget/features/ledger/state/account_state.dart';
import 'package:sloth_budget/features/subscriptions/widgets/subscription_detail_modal.dart';
import 'package:sloth_budget/features/subscriptions/widgets/add_subscription_modal.dart';
import 'package:sloth_budget/features/subscriptions/state/subscriptions_state.dart';
import 'package:sloth_budget/features/subscriptions/logic/monthly_equivalents.dart';

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    super.key,
    required this.sub,
  });

  final SlothSubscription sub;

  @override
  Widget build(BuildContext context) {
    final accountName =
        context.watch<AccountState>().byId(sub.accountId)?.name ??
        'Account ${sub.accountId}';

    final due = DateFormat.yMMMd().format(sub.nextDue);

    final amountText = CurrencyFormatter.compact(
      sub.amount,
      symbol: sub.currency,
    );

    final intervalLabel = intervalLabelHelper(sub.interval.name);

    return ListTile(
      leading: Icon(
        sub.isActive ? Icons.autorenew : Icons.pause_circle_outline,
        color: sub.isActive ? Colors.teal : Colors.grey,
      ),
      title: Text(
        sub.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$accountName • Next: $due • $intervalLabel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // amount + menu
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amountText,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(width: 6),
          _ActionsMenu(sub: sub),
        ],
      ),

      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          builder: (_) => SubscriptionDetailModal(sub: sub),
        );
      },
    );
  }
}

enum _SubAction { markPaid, snooze7, skipOnce, edit, delete }

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.sub});
  final SlothSubscription sub;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SubAction>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        final rootCtx = Navigator.of(context, rootNavigator: true).context;
        final state = rootCtx.read<SubscriptionState>();

        Future<void> showMsg(String msg, {bool error = false}) async {
          ScaffoldMessenger.of(rootCtx)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: error ? Colors.red : null,
              ),
            );
        }

        switch (action) {
          case _SubAction.markPaid: {
            if (!sub.isActive) {
              await showMsg('Subscription is paused', error: true);
              return;
            }
            final ok = await state.markPaid(sub: sub); // implement in state
            if (!rootCtx.mounted) return;
            if (!ok) {
              await showMsg(state.errorMessage ?? 'Mark paid failed', error: true);
              state.clearError();
            } else {
              await showMsg('Marked paid');
            }
            return;
          }

          case _SubAction.snooze7: {
            final ok = await state.snooze(sub, days: 7); // implement in state
            if (!rootCtx.mounted) return;
            if (!ok) {
              await showMsg(state.errorMessage ?? 'Snooze failed', error: true);
              state.clearError();
            } else {
              await showMsg('Snoozed 7 days');
            }
            return;
          }

          case _SubAction.skipOnce: {
            final ok = await state.skipOnce(sub); // implement in state
            if (!rootCtx.mounted) return;
            if (!ok) {
              await showMsg(state.errorMessage ?? 'Skip failed', error: true);
              state.clearError();
            } else {
              await showMsg('Skipped once');
            }
            return;
          }

          case _SubAction.edit: {
            showModalBottomSheet(
              context: rootCtx,
              isScrollControlled: true,
              useSafeArea: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              builder: (_) => AddSubscriptionModal(subscription: sub),
            );
            return;
          }

          case _SubAction.delete: {
            final confirm = await showDialog<bool>(
              context: rootCtx,
              builder: (d) => AlertDialog(
                title: const Text('Delete subscription?'),
                content: const Text('This will remove it from your list.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(d, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            final ok = await state.delete(sub.id!);
            if (!rootCtx.mounted) return;

            if (!ok) {
              await showMsg(state.errorMessage ?? 'Delete failed', error: true);
              state.clearError();
            } else {
              await showMsg('Subscription deleted');
            }
            return;
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _SubAction.markPaid,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.check_circle_outline),
            title: Text('Mark paid'),
          ),
        ),
        const PopupMenuItem(
          value: _SubAction.snooze7,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.snooze),
            title: Text('Snooze 7 days'),
          ),
        ),
        const PopupMenuItem(
          value: _SubAction.skipOnce,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.fast_forward),
            title: Text('Skip once'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _SubAction.edit,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem(
          value: _SubAction.delete,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}