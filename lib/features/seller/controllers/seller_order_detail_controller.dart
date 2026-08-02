import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final sellerOrderDetailControllerProvider =
    AsyncNotifierProvider.family<SellerOrderDetailController, Order, String>(SellerOrderDetailController.new);
