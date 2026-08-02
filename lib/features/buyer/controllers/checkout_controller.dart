import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/address.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/providers.dart';
import 'cart_controller.dart';

/// Submission state for the multi-seller checkout (BUY-07).
class CheckoutState {
  final bool submitting;
  final String? error;
  final String? lastOrderId;

  const CheckoutState({this.submitting = false, this.error, this.lastOrderId});
}

/// Places one order per seller (BUY-07), returns the first order id on success
/// so the checkout screen can route to payment.
class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<String?> submit({
    required Map<String, List<CartLine>> sellerGroups,
    required Address address,
    required int deliveryFee,
  }) async {
    state = const CheckoutState(submitting: true);
    try {
      String? firstOrderId;
      for (final entry in sellerGroups.entries) {
        final order = await ref.read(orderRepositoryProvider).create(
              CreateOrderInput(
                sellerId: entry.key,
                addressId: address.id,
                deliveryFee: deliveryFee,
                items: [
                  for (final line in entry.value)
                    CartItemInput(
                      productId: line.product.id,
                      quantityKg: line.quantityKg,
                    ),
                ],
              ),
            );
        firstOrderId ??= order.id;
      }
      state = CheckoutState(submitting: false, lastOrderId: firstOrderId);
      return firstOrderId;
    } catch (error) {
      state = CheckoutState(submitting: false, error: error.toString());
      return null;
    }
  }

  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
