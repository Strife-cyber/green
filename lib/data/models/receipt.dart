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

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        receiptNumber: json['receipt_number'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        amount: (json['amount'] as num?)?.round() ?? 0,
        deliveryFee: (json['delivery_fee'] as num?)?.round() ?? 0,
        commission: (json['commission'] as num?)?.round() ?? 0,
        status: ReceiptStatus.issued,
        issuedAt: DateTime.tryParse(json['issued_at'] as String? ?? '') ?? DateTime.now(),
      );
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

  factory ReceiptCopy.fromJson(Map<String, dynamic> json) => ReceiptCopy(
        id: json['id'] as String,
        receiptId: json['receipt_id'] as String? ?? '',
        recipientUserId: json['recipient_user_id'] as String? ?? '',
        role: ReceiptCopyRole.values.firstWhere(
          (r) => r.name == (json['recipient_role'] as String? ?? 'buyer'),
          orElse: () => ReceiptCopyRole.buyer,
        ),
        deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'] as String) : null,
      );
}
