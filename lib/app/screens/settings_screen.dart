import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sloth_budget/app/bootstrapbill/startup_provider.dart';
import 'package:sloth_budget/app/widgets/error_toast.dart';
import 'package:sloth_budget/app/strings/app_strings.dart';
import 'package:sloth_budget/app/utils/consts.dart';
import 'package:sloth_budget/app/widgets/categories_settings_section.dart';
import 'package:sloth_budget/app/widgets/info_toast.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> _currencies = [
    {'code': 'GBP', 'symbol': '£'},
    {'code': 'USD', 'symbol': '\$'},
    {'code': 'EUR', 'symbol': '€'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsStateProvider);
    final settings = settingsState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _sectionHeader(AppStrings.generalTitle),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text(AppStrings.defaultCurrency),
              subtitle: Text(
                '${settings.currencySymbol} ${settings.currencyCode}',
              ),
              onTap: () => _showCurrencyPicker(context, ref),
            ),
            const CategoriesSettingsSection(),
            _sectionHeader(AppStrings.dataTitle),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text(AppStrings.deleteHistoryTitle),
              subtitle: const Text(AppStrings.deleteHistorySubtitle),
              onTap: () => _confirmDeleteTransactions(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: const Text(AppStrings.resetAppTitle),
              subtitle: const Text(AppStrings.resetAppSubtitle),
              onTap: () => _confirmResetApp(context, ref),
            ),
            _sectionHeader(AppStrings.aboutTitle),
            FutureBuilder<String>(
              future: versionString(),
              builder: (context, snap) {
                final v = snap.data ?? '…';
                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(AppStrings.versionTitle),
                  subtitle: Text(v),
                );
              },
            ),
            if (settingsState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  settingsState.errorMessage!,
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final settingsState = ref.watch(settingsStateProvider);
            final settings = settingsState.settings;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.selectCurrencyTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._currencies.map((currency) {
                      final code = currency['code']!;
                      final symbol = currency['symbol']!;
                      final isSelected = code == settings.currencyCode;

                      return ListTile(
                        leading: Text(
                          symbol,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(code),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () async {
                          Navigator.pop(sheetContext);

                          final ok = await ref
                              .read(settingsStateProvider)
                              .setCurrency(code: code, symbol: symbol);

                          if (!sheetContext.mounted) return;

                          if (!ok) {
                            final err =
                                ref.read(settingsStateProvider).errorMessage;
                            if (err != null) {
                              ErrorToast.show(sheetContext, message: err);
                              ref.read(settingsStateProvider).clearError();
                            }
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTransactions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionsQuestion),
        content: const Text(AppStrings.deleteTransactionsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!context.mounted) return;
              await ref.read(transactionStateProvider).deleteAll();

              if (!context.mounted) return;
              await ref.read(transactionStateProvider).loadAll(force: true);

              if (!context.mounted) return;
              CustomInfoToast.show(
                context,
                message: AppStrings.historyDeleted,
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetApp(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final resetState = ref.watch(appResetStateProvider);

            return AlertDialog(
              title: const Text(AppStrings.resetAppQuestion),
              content: const Text(AppStrings.resetAppBody),
              actions: [
                TextButton(
                  onPressed: resetState.loading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: resetState.loading
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);

                          final ok = await ref.read(appResetStateProvider).reset();

                          if (!context.mounted) return;

                          if (ok) {
                            CustomInfoToast.show(
                              context,
                              message: AppStrings.resetComplete,
                            );
                            ref.invalidate(startupProvider);
                          } else {
                            final err =
                                ref.read(appResetStateProvider).errorMessage ??
                                AppStrings.resetFail;
                            ErrorToast.show(context, message: err);
                            ref.read(appResetStateProvider).clearError();
                          }
                        },
                  child: resetState.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.reset),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}