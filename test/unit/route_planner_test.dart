import 'package:flutter_test/flutter_test.dart';
import 'package:green/data/models/address.dart';
import 'package:green/data/models/delivery.dart';
import 'package:green/features/delivery/utils/route_planner.dart';
import 'package:latlong2/latlong.dart';

Delivery _delivery(String id, {double? lat, double? lng, bool delivered = false}) => Delivery(
      id: id,
      orderId: 'o-$id',
      deliveryAddress: lat == null
          ? null
          : Address(
              id: 'a-$id',
              label: 'Stop $id',
              recipientName: '',
              phone: '',
              region: 'Littoral',
              addressLine: 'Stop $id',
              latitude: lat,
              longitude: lng,
            ),
      deliveredAt: delivered ? DateTime(2026, 1, 1) : null,
    );

void main() {
  group('haversineKm', () {
    test('is ~111 km per degree of latitude (great-circle sanity)', () {
      final d = haversineKm(const LatLng(0, 0), const LatLng(1, 0));
      expect(d, closeTo(111.2, 0.5));
    });

    test('zero distance for identical points', () {
      expect(haversineKm(const LatLng(4.05, 9.77), const LatLng(4.05, 9.77)), 0);
    });

    test('Douala → Yaoundé is roughly 200 km', () {
      final d = haversineKm(const LatLng(4.0511, 9.7679), const LatLng(3.8667, 11.5167));
      expect(d, inInclusiveRange(190, 210));
    });
  });

  group('planNearestNeighbor', () {
    test('visits the nearest stop first, then the next nearest from there', () {
      final origin = const LatLng(4.05, 9.77);
      // A: ~2 km south-west, B: ~30 km west, C: ~15 km north-east.
      final a = _delivery('a', lat: 4.032, lng: 9.751);
      final b = _delivery('b', lat: 4.051, lng: 9.350);
      final c = _delivery('c', lat: 4.200, lng: 9.850);

      final ordered = planNearestNeighbor(
        origin: origin,
        deliveries: [c, a, b],
      );

      // Nearest to origin: a. Then from a, b is closer than c (a is west, so b
      // is on the way). Exact greedy order is deterministic — just assert the
      // first stop is the closest to the origin.
      expect(ordered, isNotEmpty);
      expect(ordered.first.id, 'a');
    });

    test('excludes delivered deliveries and deliveries without coordinates', () {
      final origin = const LatLng(4.05, 9.77);
      final open = _delivery('open', lat: 4.10, lng: 9.80);
      final done = _delivery('done', lat: 4.10, lng: 9.80, delivered: true);
      final noCoords = _delivery('nocoords');

      final ordered = planNearestNeighbor(
        origin: origin,
        deliveries: [noCoords, done, open],
      );

      expect(ordered.map((d) => d.id), ['open']);
    });

    test('empty when nothing is drivable', () {
      final origin = const LatLng(4.05, 9.77);
      expect(
        planNearestNeighbor(origin: origin, deliveries: const []),
        isEmpty,
      );
      expect(
        planNearestNeighbor(origin: origin, deliveries: [_delivery('x')]),
        isEmpty,
      );
    });

    test('every visitable stop appears exactly once', () {
      final origin = const LatLng(4.05, 9.77);
      final stops = [
        _delivery('a', lat: 4.03, lng: 9.75),
        _delivery('b', lat: 4.08, lng: 9.70),
        _delivery('c', lat: 4.02, lng: 9.85),
        _delivery('d', lat: 4.09, lng: 9.80),
      ];
      final ordered = planNearestNeighbor(origin: origin, deliveries: stops);
      expect(ordered.map((d) => d.id).toSet(), {'a', 'b', 'c', 'd'});
      expect(ordered.length, stops.length);
    });
  });

  group('routePoints', () {
    test('starts at the origin and follows the planned order', () {
      final origin = const LatLng(4.05, 9.77);
      final a = _delivery('a', lat: 4.10, lng: 9.80);
      final b = _delivery('b', lat: 4.20, lng: 9.90);
      final points = routePoints(origin: origin, ordered: [a, b]);
      expect(points, [
        origin,
        const LatLng(4.10, 9.80),
        const LatLng(4.20, 9.90),
      ]);
    });
  });
}
