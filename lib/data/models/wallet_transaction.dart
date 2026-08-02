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

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as String,
        walletId: json['wallet_id'] as String? ?? '',
        orderId: json['order_id'] as String?,
        type: TransactionType.fromApi(json['type'] as String? ?? 'payment_in'),
        status: TransactionStatus.fromApi(json['status'] as String? ?? 'reconciled'),
        amount: (json['amount'] as num?)?.round() ?? 0,
        balanceAfter: (json['balance_after'] as num?)?.round() ?? 0,
        reference: json['reference'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
