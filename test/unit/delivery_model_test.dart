import 'package:flutter_test/flutter_test.dart';
import 'package:green/data/models/delivery.dart';

void main() {
  group('Delivery.fromJson destination parsing', () {
    test('parses the destination nested under order (backend contract)', () {
      final delivery = Delivery.fromJson({
        'id': 'd-9',
        'orderId': 'o-9',
        'currentLatitude': '4.0555',
        'currentLongitude': '9.7722',
        'order': {
          'id': 'o-9',
          'status': 'CONFIRMED',
          'deliveryAddress': {
            'id': 'a-9',
            'label': 'Home',
            'recipientName': 'Marie Ngon',
            'phone': '655000001',
            'region': 'Littoral',
            'addressLine': 'Akwa, Douala',
            'latitude': '4.0511', // Prisma Decimal → string on the wire
            'longitude': '9.7679',
          },
        },
      });

      expect(delivery.deliveryAddress, isNotNull);
      expect(delivery.deliveryAddress!.label, 'Home');
      expect(delivery.deliveryAddress!.latitude, 4.0511);
      expect(delivery.deliveryAddress!.longitude, 9.7679);
      expect(delivery.destinationLatitude, 4.0511);
      expect(delivery.destinationLongitude, 9.7679);
      expect(delivery.hasDestination, isTrue);
    });

    test('falls back to a flat deliveryAddress for older responses', () {
      final delivery = Delivery.fromJson({
        'id': 'd-10',
        'orderId': 'o-10',
        'deliveryAddress': {
          'latitude': 3.8667,
          'longitude': 11.5167,
        },
      });

      expect(delivery.destinationLatitude, 3.8667);
      expect(delivery.destinationLongitude, 11.5167);
      expect(delivery.hasDestination, isTrue);
    });

    test('hasDestination is false when the order has no saved address', () {
      final delivery = Delivery.fromJson({
        'id': 'd-11',
        'orderId': 'o-11',
        'order': {'id': 'o-11', 'status': 'CONFIRMED', 'deliveryAddress': null},
      });

      expect(delivery.deliveryAddress, isNull);
      expect(delivery.hasDestination, isFalse);
    });

    test('hasDestination is false when coordinates are missing entirely', () {
      final delivery = Delivery.fromJson({
        'id': 'd-12',
        'orderId': 'o-12',
      });

      expect(delivery.deliveryAddress, isNull);
      expect(delivery.hasDestination, isFalse);
    });
  });
}
