import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery.dart';
import '../../../data/repositories/providers.dart';

/// One delivery's detail plus the driver's pickup / deliver actions (DRV-03).
class DriverDeliveryDetailController
    extends FamilyAsyncNotifier<Delivery, String> {
  @override
  Future<Delivery> build(String id) =>
      ref.watch(deliveryRepositoryProvider).get(id);

  /// Confirms the driver collected the goods from the seller.
  Future<Delivery> confirmPickup() async {
    final updated = await ref.read(deliveryRepositoryProvider).pickup(arg);
    state = AsyncData(updated);
    return updated;
  }

  /// Driver hands off to the buyer: the backend issues a 6-digit code and sends
  /// it to the buyer (DEL-07). The order is not delivered until the buyer
  /// confirms the code.
  Future<Delivery> completeDelivery() async {
    final updated = await ref.read(deliveryRepositoryProvider).complete(arg);
    state = AsyncData(updated);
    return updated;
  }
}

final driverDeliveryDetailControllerProvider =
    AsyncNotifierProvider.family<DriverDeliveryDetailController, Delivery, String>(
  DriverDeliveryDetailController.new,
);
