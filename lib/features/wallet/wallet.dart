/// Mirrors walletRepository.js's getWalletSummary() field-for-field.
class Wallet {
  final int clientId;
  final double balance;
  final double creditLimit;
  final double lowBalanceThreshold;
  final double suspendThreshold;
  final bool autoTopupEnabled;
  final double? autoTopupAmount;
  final String status;

  Wallet({
    required this.clientId,
    required this.balance,
    required this.creditLimit,
    required this.lowBalanceThreshold,
    required this.suspendThreshold,
    required this.autoTopupEnabled,
    required this.autoTopupAmount,
    required this.status,
  });

  bool get isLowBalance => balance <= lowBalanceThreshold;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        clientId: json['client_id'] as int,
        balance: double.parse(json['balance'].toString()),
        creditLimit: double.parse(json['credit_limit'].toString()),
        lowBalanceThreshold: double.parse(json['low_balance_threshold'].toString()),
        suspendThreshold: double.parse(json['suspend_threshold'].toString()),
        autoTopupEnabled: json['auto_topup_enabled'] == 1 || json['auto_topup_enabled'] == true,
        autoTopupAmount: json['auto_topup_amount'] != null ? double.parse(json['auto_topup_amount'].toString()) : null,
        status: json['status'] as String,
      );
}

class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as int,
        type: json['type'] as String,
        amount: double.parse(json['amount'].toString()),
        balanceBefore: double.parse(json['balance_before'].toString()),
        balanceAfter: double.parse(json['balance_after'].toString()),
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
