import '../models/delivery.dart';

/// Deliveries — assignment, driver actions, live tracking (DEL-02..05, DRV).
abstract class DeliveryRepository {
  Future<Delivery> assign(String orderId, String driverId);
  Future<List<Delivery>> driverOrders();
  Future<Delivery> get(String id);
  Future<Delivery> pickup(String id);
  Future<Delivery> deliver(String id);
}
