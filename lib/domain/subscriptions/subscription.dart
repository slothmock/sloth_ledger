import 'package:sloth_budget/domain/subscriptions/subscription_enums.dart';

class SlothSubscription {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final SubscriptionInterval interval;
  final DateTime nextDue;
  final int accountId;
  final bool isActive;

  SlothSubscription({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.interval,
    required this.nextDue,
    required this.accountId,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'currency': currency,
    'interval': interval.dbValue,
    'next_due': nextDue.millisecondsSinceEpoch,
    'account_id': accountId,
    'is_active': isActive ? 1 : 0,
  };

  factory SlothSubscription.fromMap(Map<String, dynamic> m) {
    return SlothSubscription(
      id: m['id'] as int?,
      name: m['name'] as String,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      currency: (m['currency'] as String?) ?? 'GBP',
      interval: SubscriptionInterval.fromDb(m['interval'] as String?),
      nextDue: DateTime.fromMillisecondsSinceEpoch(m['next_due'] as int),
      accountId: (m['account_id'] as int?) ?? 0,
      isActive: ((m['is_active'] ?? 1) as int) == 1,
    );
  }
}