import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Deliveries assigned in this app session, keyed by order id. The live backend
/// has not always redeployed the `delivery` include on `GET /orders/:id`, so
/// this cache is what keeps "Mark as shipped" unlocked after a successful
/// `assign()` even when a status update or refetch returns an order without the
/// nested delivery. Once the backend echoes `delivery`, its value wins.
final assignedDeliveriesProvider =
    StateProvider<Map<String, Delivery>>((ref) {
  // Session-scoped cache — reset when the account switches.
  ref.watch(currentUserIdProvider);
  return const {};
});

/// Loads a single seller order and drives its status transitions (SELL-03).
class SellerOrderDetailController extends FamilyAsyncNotifier<Order, String> {
  @override
  Future<Order> build(String arg) async {
    // Scoped to the signed-in user — a logout → login refetches instead of
    // serving the previous seller's cached order.
    if (ref.watch(currentUserIdProvider) == null) {
      throw StateError('signed out');
    }
    final order = await ref.watch(orderRepositoryProvider).get(arg);
    return _mergeAssigned(order);
  }

  /// Moves the order to [status] and reflects it in the state.
  Future<void> updateStatus(OrderStatus status) async {
    final updated = await ref.read(orderRepositoryProvider).updateStatus(arg, status);
    state = AsyncData(_mergeAssigned(updated));
  }

  /// Records a successfully created delivery (DEL-02) on the order so the
  /// seller can mark the order SHIPPED immediately, without waiting for the
  /// backend to echo the delivery back on a subsequent order fetch.
  void deliveryAssigned(Delivery delivery) {
    ref.read(assignedDeliveriesProvider.notifier).update((map) => {...map, arg: delivery});
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(_mergeAssigned(current));
  }

  /// Re-applies a delivery assigned this session when the backend payload
  /// omits it (pre-redeploy `GET /orders/:id` responses and PATCH status
  /// updates both leave `delivery` out). Backend-provided deliveries win.
  Order _mergeAssigned(Order order) {
    if (order.deliveryId != null) return order;
    final assigned = ref.read(assignedDeliveriesProvider)[order.id];
    if (assigned == null) return order;
    return Order(
      id: order.id,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      status: order.status,
      paymentStatus: order.paymentStatus,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      totalAmount: order.totalAmount,
      deliveryAddressLabel: order.deliveryAddressLabel,
      deliveryId: assigned.id,
      deliveryDriverName: assigned.driverName,
      items: order.items,
      placedAt: order.placedAt,
      deliveredAt: order.deliveredAt,
    );
  }
}

final sellerOrderDetailControllerProvider =
    AsyncNotifierProvider.family<SellerOrderDetailController, Order, String>(SellerOrderDetailController.new);
