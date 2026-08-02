import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The current buyer's orders (BUY-09), scoped to the signed-in user.
class BuyerOrderListController extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final userId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    final orders = await ref.watch(orderRepositoryProvider).buyerOrders();
    if (userId == null) return const [];
    return [
      for (final order in orders)
        if (order.buyerId == userId) order,
    ];
  }
}

final buyerOrderListControllerProvider =
    AsyncNotifierProvider<BuyerOrderListController, List<Order>>(
  BuyerOrderListController.new,
);
