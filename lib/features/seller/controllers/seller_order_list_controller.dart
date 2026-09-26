import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Orders placed with the signed-in seller (SELL-02). Scoped to the account —
/// a logout → login refetches instead of serving the previous seller's queue.
class SellerOrderListController extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(orderRepositoryProvider).sellerOrders();
  }

  /// Re-fetches the list (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final sellerOrderListControllerProvider =
    AsyncNotifierProvider<SellerOrderListController, List<Order>>(SellerOrderListController.new);
