/// Mobile-money payment channels (PAY-01/02). Providers are stubbed on the
/// backend until real SDK integration.
enum PaymentChannel { mtnMomo, orangeMoney }

/// Flow state of a payment attempt (distinct from [PaymentStatus] on orders).
enum PaymentResultStatus { pending, success, failed }

/// Result of initiating or polling a payment.
class PaymentResult {
  final String orderId;
  final PaymentResultStatus status;
  final String? reference;

  const PaymentResult({
    required this.orderId,
    required this.status,
    this.reference,
  });
}

/// MTN MoMo / Orange Money payments (PAY-01/02/08).
abstract class PaymentRepository {
  Future<PaymentResult> initiate(String orderId, PaymentChannel channel);
  Future<PaymentResult> status(String orderId);
}
