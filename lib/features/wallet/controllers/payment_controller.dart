import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/providers.dart';

/// Flow state of the current payment attempt (distinct from the order's
/// [PaymentStatus]).
sealed class PaymentState {
  const PaymentState();
}

class PaymentIdle extends PaymentState {
  const PaymentIdle();
}

class PaymentInitiating extends PaymentState {
  const PaymentInitiating();
}

class PaymentSuccess extends PaymentState {
  final PaymentResult result;
  const PaymentSuccess(this.result);
}

class PaymentFailure extends PaymentState {
  final String message;
  const PaymentFailure(this.message);
}

/// Drives a mobile-money payment attempt (PAY-01/02).
class PaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentIdle();

  Future<void> pay({required String orderId, required PaymentChannel channel}) async {
    state = const PaymentInitiating();
    try {
      final result = await ref.read(paymentRepositoryProvider).initiate(orderId, channel);
      state = PaymentSuccess(result);
    } catch (_) {
      state = const PaymentFailure('Payment failed. Please check your connection and try again.');
    }
  }
}

final paymentControllerProvider = NotifierProvider<PaymentController, PaymentState>(PaymentController.new);
