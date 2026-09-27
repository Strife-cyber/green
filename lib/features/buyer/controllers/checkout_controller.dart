import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/address.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';
import 'cart_controller.dart';

/// One successfully-created order (per seller group) from a multi-seller
/// checkout (BUY-07). Keeps the seller id so the screen can drop exactly those
/// cart lines when a later group fails.
class PlacedOrder {
  final String sellerId;
  final String orderId;
  final PaymentStatus paymentStatus;

  const PlacedOrder({
    required this.sellerId,
    required this.orderId,
    required this.paymentStatus,
  });
}

/// The outcome of [CheckoutController.submit]. Always carries every order that
/// was actually created, so a partial failure can still take the buyer to
/// payment for the orders that did go through.
class CheckoutResult {
  final List<PlacedOrder> placedOrders;
  final int failedGroups;
  final String? error;

  const CheckoutResult({
    required this.placedOrders,
    this.failedGroups = 0,
    this.error,
  });

  /// Every seller group produced an order.
  bool get allSucceeded => placedOrders.isNotEmpty && failedGroups == 0;

  /// Some orders were placed but others failed — pay the placed ones, retry
  /// the rest.
  bool get partial => placedOrders.isNotEmpty && failedGroups > 0;

  /// Nothing was placed — the whole checkout failed.
  bool get failed => placedOrders.isEmpty;
}

/// Submission state for the multi-seller checkout (BUY-07).
class CheckoutState {
  final bool submitting;
  final String? error;
  final CheckoutResult? result;

  const CheckoutState({this.submitting = false, this.error, this.result});
}

/// Places one order per seller (BUY-07) and returns every created order's id +
/// payment status. A failed seller group does NOT abort the others, so a
/// partial checkout still leaves the placed orders payable.
class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    // Resets leftover submit/result state on account switch.
    ref.watch(currentUserIdProvider);
    return const CheckoutState();
  }

  Future<CheckoutResult> submit({
    required Map<String, List<CartLine>> sellerGroups,
    required Address address,
    required int deliveryFee,
  }) async {
    state = const CheckoutState(submitting: true);
    final placed = <PlacedOrder>[];
    var failedGroups = 0;
    String? lastError;
    for (final entry in sellerGroups.entries) {
      try {
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
        placed.add(PlacedOrder(
          sellerId: entry.key,
          orderId: order.id,
          paymentStatus: order.paymentStatus,
        ));
      } catch (error) {
        failedGroups++;
        lastError = error.toString();
      }
    }
    final result = CheckoutResult(
      placedOrders: placed,
      failedGroups: failedGroups,
      error: lastError,
    );
    state = CheckoutState(
      submitting: false,
      error: placed.isEmpty ? lastError : null,
      result: result,
    );
    return result;
  }

  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
