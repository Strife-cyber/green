import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/delivery.dart';
import '../../../theme/app_colors.dart';

/// Route planning map (DRV-06): the driver's live position as the origin, the
/// planned stops as numbered markers in visit order, and the connecting route
/// as a polyline. Camera auto-fits the whole planned route.
class RouteMap extends StatelessWidget {
  /// The driver's current position — the route starts here.
  final LatLng origin;

  /// Planned stops in visit order (from [planNearestNeighbor]).
  final List<Delivery> stops;

  final double height;

  const RouteMap({
    super.key,
    required this.origin,
    required this.stops,
    this.height = 260,
  });

  /// Douala city centre — fallback origin when no GPS fix is available.
  static const fallbackOrigin = LatLng(4.0511, 9.7679);

  static const _tileTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    final points = [origin, for (final d in stops) _pointOf(d)];
    final route = Polyline(
      points: List.unmodifiable(points),
      strokeWidth: 4,
      color: AppColors.green.withValues(alpha: 0.7),
      // strokeCap defaults to round in flutter_map v8.
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: origin,
            initialZoom: 14,
            // Shrink the fit a little so edge markers aren't clipped by the
            // rounded corners / marker bounds.
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(48),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _tileTemplate,
              subdomains: _tileSubdomains,
              retinaMode: true,
              userAgentPackageName: 'com.example.green',
            ),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [route],
                // Numbered markers sit above the route line.
              ),
            MarkerLayer(
              markers: [
                _driverMarker(origin),
                for (var i = 0; i < stops.length; i++) _stopMarker(i + 1, stops[i]),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors © CARTO'),
              ],
              popupBackgroundColor: AppColors.backgroundElevated,
              showFlutterMapAttribution: false,
            ),
          ],
        ),
      ),
    );
  }

  LatLng _pointOf(Delivery d) => LatLng(d.destinationLatitude!, d.destinationLongitude!);

  Marker _driverMarker(LatLng point) => Marker(
        point: point,
        width: 56,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
        ),
      );

  Marker _stopMarker(int number, Delivery delivery) => Marker(
        point: _pointOf(delivery),
        width: 56,
        height: 56,
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            // A short pointer tail so the number sits just above the point.
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
            ),
          ],
        ),
      );
}
