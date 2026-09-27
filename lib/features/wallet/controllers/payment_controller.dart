import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../buyer/controllers/buyer_order_list_controller.dart';
import '../../buyer/controllers/order_detail_controller.dart';

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

/// Drives a mobile-money payment attempt (PAY-01/02), keyed by order so one
/// order's result never leaks into another's checkout screen.
class PaymentController extends FamilyNotifier<PaymentState, String> {
  @override
  PaymentState build(String arg) => const PaymentIdle();

  Future<void> pay({required String orderId, required PaymentChannel channel}) async {
    state = const PaymentInitiating();
    try {
      final result = await ref.read(paymentRepositoryProvider).initiate(orderId, channel);
      state = PaymentSuccess(result);
      // The order list shows its own "Pay now" affordance — refetch so the
      // just-paid order loses it without waiting for a manual refresh.
      ref.invalidate(buyerOrderListControllerProvider);
      ref.invalidate(orderDetailControllerProvider);
    } catch (_) {
      state = const PaymentFailure('Payment failed. Please check your connection and try again.');
    }
  }
}

final paymentControllerProvider =
    NotifierProvider.family<PaymentController, PaymentState, String>(PaymentController.new);
