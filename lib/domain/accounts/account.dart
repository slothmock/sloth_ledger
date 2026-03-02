import 'package:sloth_budget/domain/accounts/account_enums.dart';

class SlothAccount {
  final int? id;
  final String name;

  final AccountCategory category;
  final AccountType type;

  final String currency;
  final double openingBalance;
  final DateTime createdAt;

  SlothAccount({
    this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.currency,
    required this.openingBalance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.dbValue,
      'type': type.dbValue,
      'currency': currency,
      'opening_balance': openingBalance,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SlothAccount.fromMap(Map<String, dynamic> map) {
    return SlothAccount(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: AccountCategoryX.fromDb(map['category'] as String?),
      type: AccountTypeX.fromDb(map['type'] as String?),
      currency: map['currency'] as String,
      openingBalance: ((map['opening_balance'] ?? 0) as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  String get categoryLabel => category.label;
  String get typeLabel => type.label;
}
