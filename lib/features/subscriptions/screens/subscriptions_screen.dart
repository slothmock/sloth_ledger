import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sloth_ledger/app/bootstrapbill/startup_provider.dart';

import 'package:sloth_ledger/app/strings/app_strings.dart';
import 'package:sloth_ledger/app/widgets/error_toast.dart';
import 'package:sloth_ledger/app/widgets/info_toast.dart';
import 'package:sloth_ledger/features/subscriptions/subscriptions.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  Future<void> _refresh(BuildContext context) async {
    await ref.read(subscriptionStateProvider).load(force: true);
    if (!context.mounted) return;
    final error = ref.read(subscriptionStateProvider).errorMessage;
    if (error != null) {
      if (!context.mounted) return;
      ErrorToast.show(context, message: error);
    } else if (ref.read(subscriptionStateProvider).all.isEmpty) {
      if (!context.mounted) return;
      CustomInfoToast.show(
        context,
        message: AppStrings.subsNotFound
      );
    } else {
      if (!context.mounted) return;
      CustomInfoToast.show(context, message: AppStrings.subsRefreshed);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionStateProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionStateProvider);

    final subs = List.of(subState.all)
      ..sort((a, b) {
        // active first
        final ac = (b.isActive ? 1 : 0) - (a.isActive ? 1 : 0);
        if (ac != 0) return ac;

        // soonest due first
        final dc = a.nextDue.compareTo(b.nextDue);
        if (dc != 0) return dc;

        // name
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.subscriptionsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: Builder(
          builder: (context) {
            // LOADING
            if (subState.loading && subs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            // ERROR
            if (subState.errorMessage != null && subs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      subState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            // EMPTY
            if (subs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 140),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        Icon(
                          Icons.autorenew,
                          size: 52,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.noSubscriptions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.addSubsBody,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              builder: (_) => const AddSubscriptionModal(),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(AppStrings.addSubscription),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // DATA
            final grouped = groupSubs(subs);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 8),

                // Dashboard
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SubscriptionsSummaryCard(
                    overdueCount: grouped.overdue.length,
                    overdueTotal: sumAmount(grouped.overdue),
                    dueSoonCount: grouped.dueSoon.length,
                    dueSoonTotal: sumAmount(grouped.dueSoon),
                    activeCount:
                        grouped.overdue.length +
                        grouped.dueSoon.length +
                        grouped.later.length,
                    pausedCount: grouped.paused.length,
                  ),
                ),

                const SizedBox(height: 8),

                if (grouped.overdue.isNotEmpty)
                  _section(
                    context,
                    title: AppStrings.subOverdue,
                    subtitle:
                        '${grouped.overdue.length} • ${sumAmount(grouped.overdue).toStringAsFixed(2)}',
                    icon: Icons.warning_amber,
                    children: grouped.overdue
                        .map((s) => SubscriptionTile(sub: s))
                        .toList(),
                  ),

                if (grouped.dueSoon.isNotEmpty)
                  _section(
                    context,
                    title: AppStrings.subDueSoon,
                    subtitle:
                        '${grouped.dueSoon.length} • ${sumAmount(grouped.dueSoon).toStringAsFixed(2)}',
                    icon: Icons.schedule,
                    children: grouped.dueSoon
                        .map((s) => SubscriptionTile(sub: s))
                        .toList(),
                  ),

                if (grouped.later.isNotEmpty)
                  _section(
                    context,
                    title: AppStrings.subDueLater,
                    subtitle: '${grouped.later.length}',
                    icon: Icons.event_available,
                    children: grouped.later
                        .map((s) => SubscriptionTile(sub: s))
                        .toList(),
                  ),

                if (grouped.paused.isNotEmpty)
                  _section(
                    context,
                    title: AppStrings.subPaused,
                    subtitle: '${grouped.paused.length}',
                    icon: Icons.pause_circle_outline,
                    children: grouped.paused
                        .map((s) => SubscriptionTile(sub: s))
                        .toList(),
                  ),

                const SizedBox(height: 80), // space for FAB
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _section(
  BuildContext context, {
  required String title,
  String? subtitle,
  required IconData icon,
  required List<Widget> children,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _SubscriptionsSummaryCard extends StatelessWidget {
  const _SubscriptionsSummaryCard({
    required this.overdueCount,
    required this.overdueTotal,
    required this.dueSoonCount,
    required this.dueSoonTotal,
    required this.activeCount,
    required this.pausedCount,
  });

  final int overdueCount;
  final double overdueTotal;
  final int dueSoonCount;
  final double dueSoonTotal;
  final int activeCount;
  final int pausedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.overviewTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metric(AppStrings.subOverdue, '$overdueCount')),
                Expanded(child: _metric(AppStrings.subDueSoon, '$dueSoonCount')),
                Expanded(child: _metric(AppStrings.subActive, '$activeCount')),
                Expanded(child: _metric(AppStrings.subPaused, '$pausedCount')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
