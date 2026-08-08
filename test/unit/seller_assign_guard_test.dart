import 'package:flutter_test/flutter_test.dart';

import 'package:green/data/mock/mock_repositories.dart';
import 'package:green/data/mock/mock_store.dart';
import 'package:green/data/models/enums.dart';
import 'package:green/data/models/order.dart';

/// The seller-side delivery-assignment contract (DEL-02): the order payload
/// exposes the assigned delivery, and the seller screen gates "mark as
/// shipped" on it so an order can never reach SHIPPED with no driver.
void main() {
  group('Order.fromJson delivery parsing (backend contract)', () {
    test('parses the nested delivery with its driver', () {
      final order = Order.fromJson({
        'id': 'o-1',
        'status': 'CONFIRMED',
        'delivery': {
          'id': 'd-1',
          'driver': {'firstName': 'Jean', 'lastName': 'Kamdem'},
        },
      });

      expect(order.deliveryId, 'd-1');
      expect(order.deliveryDriverName, 'Jean Kamdem');
    });

    test('delivery fields are null when no driver is assigned', () {
      final order = Order.fromJson({
        'id': 'o-1',
        'status': 'CONFIRMED',
        'delivery': null,
      });

      expect(order.deliveryId, isNull);
      expect(order.deliveryDriverName, isNull);
    });

    test('legacy flat deliveryId key still works', () {
      final order = Order.fromJson({
        'id': 'o-1',
        'status': 'CONFIRMED',
        'deliveryId': 'd-1',
      });

      expect(order.deliveryId, 'd-1');
      expect(order.deliveryDriverName, isNull);
    });
  });

  group('Mock order + delivery repositories (seller guard data)', () {
    test('an assigned delivery shows up on the order (guard unlocks)', () async {
      final store = MockStore();
      final deliveryRepo = MockDeliveryRepository(store);
      final orderRepo = MockOrderRepository(store);

      // A confirmed order with no delivery assigned yet.
      store.orders.insert(
        0,
        Order(
          id: 'o-unassigned',
          buyerId: 'u-buyer-1',
          sellerId: 'u-seller-1',
          status: OrderStatus.confirmed,
          paymentStatus: PaymentStatus.unpaid,
          subtotal: 3000,
          deliveryFee: 500,
          totalAmount: 3500,
          items: const [],
          placedAt: DateTime(2026, 8, 1),
        ),
      );

      // No delivery → the guard blocks shipping.
      var order = await orderRepo.get('o-unassigned');
      expect(order.deliveryId, isNull);

      // Seller assigns a driver → the delivery record exists.
      final delivery = await deliveryRepo.assign('o-unassigned', 'u-driver-1');

      order = await orderRepo.get('o-unassigned');
      expect(order.deliveryId, delivery.id);
      expect(order.deliveryDriverName, delivery.driverName);
      expect(order.deliveryDriverName, isNotEmpty);
    });

    test('availableDrivers lists the DRIVER users a seller may pick from', () async {
      final repo = MockDeliveryRepository(MockStore());
      final drivers = await repo.availableDrivers();

      expect(drivers, isNotEmpty);
      expect(drivers.every((d) => d.role == UserRole.driver), isTrue);
      expect(drivers.first.fullName, isNotEmpty);
    });
  });
}
