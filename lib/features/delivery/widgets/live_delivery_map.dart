import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/delivery.dart';
import '../../../theme/app_colors.dart';

/// OSM map with a branded marker at the delivery's latest position (DEL-04).
///
/// Falls back to a fixed centre so a marker always renders — even before the
/// driver starts sharing coordinates. Tile failures are safe to ignore: the
/// marker layer still draws and the widget only needs to compile and render.
class LiveDeliveryMap extends StatefulWidget {
  final Delivery? delivery;
  final double height;

  const LiveDeliveryMap({super.key, this.delivery, this.height = 240});

  @override
  State<LiveDeliveryMap> createState() => _LiveDeliveryMapState();
}

class _LiveDeliveryMapState extends State<LiveDeliveryMap> {
  /// Douala city centre — used until the driver shares a real position.
  static const _fallback = LatLng(4.0511, 9.7679);
  final MapController _controller = MapController();

  LatLng _centerFor(Delivery? delivery) {
    final lat = delivery?.currentLatitude;
    final lng = delivery?.currentLongitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    return _fallback;
  }

  @override
  void didUpdateWidget(LiveDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _centerFor(widget.delivery);
    final prev = _centerFor(oldWidget.delivery);
    if (next != prev) {
      // Follow the marker as the driver's position updates.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(next, 15);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _centerFor(widget.delivery);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(initialCenter: center, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.greenish.trendy',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
