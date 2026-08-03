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

  /// Parses the backend `WithdrawalItemDto` — camelCase, amount as decimal
  /// string, `channel`/`status` uppercase.
  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: json['id'] as String,
        walletId: json['walletId'] as String? ?? json['wallet_id'] as String? ?? '',
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        amount: _toInt(json['amount']),
        channel: WithdrawalChannel.fromApi(json['channel'] as String? ?? 'mtn_momo'),
        accountReference: json['accountReference'] as String? ?? json['account_reference'] as String? ?? '',
        status: WithdrawalStatus.fromApi(json['status'] as String? ?? 'pending'),
        requestedAt: _dateOrNull(json['requestedAt'] ?? json['requested_at']),
        processedAt: _dateOrNull(json['processedAt'] ?? json['processed_at']),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round() ?? 0;
  }

  static DateTime? _dateOrNull(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
