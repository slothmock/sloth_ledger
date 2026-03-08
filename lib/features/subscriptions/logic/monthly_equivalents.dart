import 'package:sloth_ledger/domain/subscriptions/subscription.dart';
import 'package:sloth_ledger/domain/subscriptions/subscription_enums.dart';

double monthlyEquivalent(SlothSubscription s) {
  switch (s.interval) {
    case SubscriptionInterval.weekly:
      return s.amount * (52.0 / 12.0);
    case SubscriptionInterval.monthly:
      return s.amount;
    case SubscriptionInterval.quarterly:
      return s.amount * 4.0 / 12.0;
    case SubscriptionInterval.yearly:
      return s.amount / 12.0;
  }
}

String intervalLabelHelper(String raw) {
  switch (raw) {
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'yearly':
      return 'Yearly';
    default:
      // Future: custom intervals
      return raw;
  }
}
