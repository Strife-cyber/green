import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';

/// Loads a single seller order and drives its status transitions (SELL-03).
class SellerOrderDetailController extends FamilyAsyncNotifier<Order, String> {
  @override
  Future<Order> build(String arg) async {
    return ref.watch(orderRepositoryProvider).get(arg);
  }

  /// Moves the order to [status] and reflects it in the state.
  Future<void> updateStatus(OrderStatus status) async {
    final updated = await ref.read(orderRepositoryProvider).updateStatus(arg, status);
    state = AsyncData(updated);
  }

  /// Records a successfully created delivery (DEL-02) on the order so the
  /// seller can mark the order SHIPPED immediately, without waiting for the
  /// backend to echo the delivery back on a subsequent order fetch.
  void deliveryAssigned(Delivery delivery) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Order(
      id: current.id,
      buyerId: current.buyerId,
      sellerId: current.sellerId,
      sellerName: current.sellerName,
      status: current.status,
      paymentStatus: current.paymentStatus,
      subtotal: current.subtotal,
      deliveryFee: current.deliveryFee,
      totalAmount: current.totalAmount,
      deliveryAddressLabel: current.deliveryAddressLabel,
      deliveryId: delivery.id,
      deliveryDriverName: delivery.driverName,
      items: current.items,
      placedAt: current.placedAt,
      deliveredAt: current.deliveredAt,
    ));
  }
}

final sellerOrderDetailControllerProvider =
    AsyncNotifierProvider.family<SellerOrderDetailController, Order, String>(SellerOrderDetailController.new);
