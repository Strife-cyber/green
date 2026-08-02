import '../models/enums.dart';
import '../models/order.dart';

/// Orders — transactional checkout, per-role lists, status state machine
/// (BUY-07/09/10, SELL-02, DEL-01).
abstract class OrderRepository {
  Future<Order> create(CreateOrderInput input);
  Future<List<Order>> buyerOrders();
  Future<List<Order>> sellerOrders();
  Future<Order> get(String id);
  Future<Order> updateStatus(String id, OrderStatus status);
  Future<List<OrderStatusHistory>> statusHistory(String id);
}

/// One order covers items from a single seller (BUY-07: one order per seller).
class CreateOrderInput {
  final String sellerId;
  final String? addressId;
  final int deliveryFee;
  final List<CartItemInput> items;

  const CreateOrderInput({
    required this.sellerId,
    this.addressId,
    this.deliveryFee = 0,
    required this.items,
  });
}

class CartItemInput {
  final String productId;
  final double quantityKg;

  const CartItemInput({required this.productId, required this.quantityKg});
}
