import '../models/delivery.dart';
import '../models/user.dart';

/// Deliveries — assignment, driver actions, live tracking (DEL-02..05, DRV).
abstract class DeliveryRepository {
  Future<Delivery> assign(String orderId, String driverId);

  /// DRIVER users the authenticated seller (or admin) may assign — the
  /// admin-console driver list is admin-only, so sellers get their own picker.
  Future<List<User>> availableDrivers();

  Future<List<Delivery>> driverOrders();
  Future<Delivery> get(String id);
  Future<Delivery> pickup(String id);

  /// Driver marks the delivery ready for hand-off (DEL-07): the backend
  /// generates a 6-digit code and sends it to the buyer. The order is NOT
  /// delivered until the buyer confirms that code via [confirm].
  Future<Delivery> complete(String id);

  /// Records the driver's latest published position (DEL-04). The live
  /// backend receives it via the `location:update` socket event (the client
  /// emits that separately), so the API implementation is a no-op — the mock
  /// implementation writes the shared store so every role's poll sees the
  /// same simulated movement.
  Future<void> reportPosition(String id, double latitude, double longitude);

  /// Buyer confirms receipt of the delivery (DEL-07).
  ///
  /// The 6-digit [code] is required only when the order total is above the
  /// code-required threshold ([Delivery.codeRequired]); otherwise the buyer
  /// confirms with a null code — the one-tap "Got it". On success the order
  /// transitions to DELIVERED, escrow is released to the seller and the
  /// receipt is issued.
  Future<Delivery> confirm(String id, {String? code});
}
