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

  /// Buyer confirms the delivery with the 6-digit code issued by the driver.
  /// On success the order transitions to DELIVERED, escrow is released to the
  /// seller and the receipt is issued.
  Future<Delivery> confirm(String id, String code);
}
