/// Payment channels (PAY-01/02): the two mobile-money rails plus the internal
/// Greenish Wallet balance.
enum PaymentChannel { mtnMomo, orangeMoney, wallet }

/// Flow state of a payment attempt (distinct from [PaymentStatus] on orders).
enum PaymentResultStatus { pending, success, failed }

/// Result of initiating or polling a payment.
class PaymentResult {
  final String orderId;
  final PaymentResultStatus status;
  final String? reference;

  /// The receipt's `GRN-…` number when the payment immediately issues one
  /// (WALLET payments settle in-line), else null — the confirmation screen
  /// then falls back to the payment [reference].
  final String? receiptNumber;

  /// The 6-digit delivery code when the payment response carries it (kept as
  /// digits-only so the confirmation screen can render it large).
  final String? deliveryCode;

  const PaymentResult({
    required this.orderId,
    required this.status,
    this.reference,
    this.receiptNumber,
    this.deliveryCode,
  });
}

/// MTN MoMo / Orange Money payments (PAY-01/02/08).
abstract class PaymentRepository {
  Future<PaymentResult> initiate(String orderId, PaymentChannel channel);
  Future<PaymentResult> status(String orderId);
}
