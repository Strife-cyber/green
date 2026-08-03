import 'enums.dart';

/// An immutable wallet ledger row (PAY-07). Amount is `int` FCFA.
class WalletTransaction {
  final String id;
  final String walletId;
  final String? orderId;
  final TransactionType type;
  final TransactionStatus status;

  /// Signed amount: positive for credits, negative for debits.
  final int amount;
  final int balanceAfter;
  final String? reference;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    this.orderId,
    required this.type,
    required this.status,
    required this.amount,
    required this.balanceAfter,
    this.reference,
    required this.createdAt,
  });

  /// Parses the backend `TransactionItemDto` — camelCase, amounts as decimal
  /// strings, `type`/`status` uppercase.
  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as String,
        walletId: json['walletId'] as String? ?? json['wallet_id'] as String? ?? '',
        orderId: json['orderId'] as String? ?? json['order_id'] as String?,
        type: TransactionType.fromApi(json['type'] as String? ?? 'payment_in'),
        status: TransactionStatus.fromApi(json['status'] as String? ?? 'success'),
        amount: _toInt(json['amount']),
        balanceAfter: _toInt(json['balanceAfter'] ?? json['balance_after']),
        reference: json['reference'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round() ?? 0;
  }
}
