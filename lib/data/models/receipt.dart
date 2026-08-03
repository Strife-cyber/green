import 'enums.dart';

/// Smart receipt issued on order completion (REC-01..04). Money is `int` FCFA.
class Receipt {
  final String id;
  final String receiptNumber;
  final String orderId;
  final int amount;
  final int deliveryFee;
  final int commission;
  final ReceiptStatus status;
  final DateTime issuedAt;

  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.orderId,
    required this.amount,
    required this.deliveryFee,
    required this.commission,
    required this.status,
    required this.issuedAt,
  });

  /// Parses the backend `ReceiptSummaryDto` — camelCase, money as decimal
  /// strings, `status` uppercase (`ISSUED`/`VOIDED`).
  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        receiptNumber: json['receiptNumber'] as String? ?? json['receipt_number'] as String? ?? '',
        orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
        amount: _toInt(json['amount']),
        deliveryFee: _toInt(json['deliveryFee'] ?? json['delivery_fee']),
        commission: _toInt(json['commission']),
        status: ReceiptStatus.fromApi(json['status'] as String? ?? 'issued'),
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? json['issued_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round() ?? 0;
  }
}

/// One of the three copies of a receipt (buyer/seller/admin) — REC-03.
class ReceiptCopy {
  final String id;
  final String receiptId;
  final String recipientUserId;
  final ReceiptCopyRole role;
  final DateTime? deliveredAt;

  const ReceiptCopy({
    required this.id,
    required this.receiptId,
    required this.recipientUserId,
    required this.role,
    this.deliveredAt,
  });

  /// Parses the backend `ReceiptListItemDto` — camelCase, `recipientRole`
  /// uppercase.
  factory ReceiptCopy.fromJson(Map<String, dynamic> json) => ReceiptCopy(
        id: json['id'] as String,
        receiptId: json['receiptId'] as String? ?? json['receipt_id'] as String? ?? '',
        recipientUserId: json['recipientUserId'] as String? ?? json['recipient_user_id'] as String? ?? '',
        role: ReceiptCopyRole.fromApi(json['recipientRole'] as String? ?? json['recipient_role'] as String? ?? 'buyer'),
        deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
      );
}
