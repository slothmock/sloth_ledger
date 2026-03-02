class SlothTransaction {
  final int? id;
  final double amount; // positive = income, negative = expense
  final String category;
  final DateTime date;
  final String? notes;
  final String? merchant;
  final int accountId;
  final String? transferGroupId;

  SlothTransaction({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.accountId,
    this.notes,
    this.merchant,
    this.transferGroupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'merchant': merchant,
      'account_id': accountId,
      'transfer_group_id': transferGroupId,
    };
  }

  factory SlothTransaction.fromMap(Map<String, dynamic> map) {
    final rawAmount = map['amount'];
    final amount = (rawAmount is int)
        ? rawAmount.toDouble()
        : (rawAmount as num).toDouble();

    return SlothTransaction(
      id: map['id'] as int?,
      amount: amount,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      merchant: map['merchant'] as String?,
      accountId: map['account_id'] as int,
      transferGroupId: map['transfer_group_id'] as String?,
    );
  }

  bool get isExpense => amount < 0;
  bool get isIncome => amount >= 0;
  bool get isTransfer =>
      (transferGroupId != null && transferGroupId!.isNotEmpty);
}
