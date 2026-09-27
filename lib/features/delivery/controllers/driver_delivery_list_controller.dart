import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The driver's assigned deliveries (DRV-02). Loaded from the delivery
/// repository and exposed as an `AsyncValue` so screens can render it with
/// [AsyncView]. Scoped to the signed-in user — a logout → login refetches
/// instead of showing the previous driver's queue.
class DriverDeliveryListController extends AsyncNotifier<List<Delivery>> {
  @override
  Future<List<Delivery>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(deliveryRepositoryProvider).driverOrders();
  }

  /// Re-fetches the list, e.g. after returning from a delivery detail screen.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final driverDeliveryListControllerProvider =
    AsyncNotifierProvider<DriverDeliveryListController, List<Delivery>>(
  DriverDeliveryListController.new,
);
