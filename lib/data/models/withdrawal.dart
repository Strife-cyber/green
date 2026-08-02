import 'enums.dart';

/// A withdrawal request, pending until an admin processes it (PAY-05).
class Withdrawal {
  final String id;
  final String walletId;
  final String userId;
  final int amount;
  final WithdrawalChannel channel;
  final String accountReference;
  final WithdrawalStatus status;
  final DateTime? requestedAt;
  final DateTime? processedAt;

  const Withdrawal({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.channel,
    required this.accountReference,
    required this.status,
    this.requestedAt,
    this.processedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: json['id'] as String,
        walletId: json['wallet_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        amount: (json['amount'] as num?)?.round() ?? 0,
        channel: WithdrawalChannel.fromApi(json['channel'] as String? ?? 'mtn_momo'),
        accountReference: json['account_reference'] as String? ?? '',
        status: WithdrawalStatus.fromApi(json['status'] as String? ?? 'pending'),
        requestedAt: json['requested_at'] != null ? DateTime.tryParse(json['requested_at'] as String) : null,
        processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'] as String) : null,
      );
}
