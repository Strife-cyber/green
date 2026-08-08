import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../data/models/delivery.dart';

/// Great-circle distance between two points, in kilometres (haversine).
double haversineKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  final dLat = _radians(b.latitude - a.latitude);
  final dLng = _radians(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_radians(a.latitude)) *
          math.cos(_radians(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(h));
}

double _radians(double degrees) => degrees * math.pi / 180;

/// Orders the driver's active stops by a nearest-neighbour heuristic starting
/// from [origin] (their current GPS fix). Deliveries that are already
/// delivered or lack a drivable destination are excluded. Route computation
/// stays on-device — the server sends destinations, never a route.
List<Delivery> planNearestNeighbor({
  required LatLng origin,
  required List<Delivery> deliveries,
}) {
  final remaining = [
    for (final d in deliveries)
      if (!d.isDelivered && d.hasDestination) d,
  ];
  if (remaining.isEmpty) return const [];

  final ordered = <Delivery>[];
  var current = origin;
  while (remaining.isNotEmpty) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final d = remaining[i];
      final distance = haversineKm(
        current,
        LatLng(d.destinationLatitude!, d.destinationLongitude!),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    final chosen = remaining.removeAt(bestIndex);
    ordered.add(chosen);
    current = LatLng(chosen.destinationLatitude!, chosen.destinationLongitude!);
  }
  return ordered;
}

/// The drawn route: the origin followed by the planned stops in order. Only
/// valid after [planNearestNeighbor] has ordered the deliveries.
List<LatLng> routePoints({
  required LatLng origin,
  required List<Delivery> ordered,
}) => [
      origin,
      for (final d in ordered)
        LatLng(d.destinationLatitude!, d.destinationLongitude!),
    ];
