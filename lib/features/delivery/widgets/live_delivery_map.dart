import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/delivery.dart';
import '../../../theme/app_colors.dart';

/// Live driver map with a custom look (DEL-04): CartoDB Voyager tiles, a
/// branded pulsing driver marker and the driver's traveled path as a green
/// trail. Follows the delivery's latest coordinates, and falls back to a fixed
/// centre so a marker always renders — even before the driver shares a
/// position. Tile failures are safe to ignore: the marker layer still draws.
class LiveDeliveryMap extends StatefulWidget {
  final Delivery? delivery;
  final double height;

  /// Invoked when the map card is tapped (e.g. to open a full-screen view).
  final VoidCallback? onTap;

  const LiveDeliveryMap({
    super.key,
    this.delivery,
    this.height = 240,
    this.onTap,
  });

  @override
  State<LiveDeliveryMap> createState() => _LiveDeliveryMapState();
}

class _LiveDeliveryMapState extends State<LiveDeliveryMap>
    with SingleTickerProviderStateMixin {
  /// Douala city centre — used until the driver shares a real position.
  static const _fallback = LatLng(4.0511, 9.7679);

  /// CartoDB Voyager raster tiles — free CDN, no API key. `{s}` picks the
  /// subdomain, `{r}` is the retina suffix (needs `retinaMode` below).
  static const _tileTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  /// Caps the trail so a long trip doesn't keep growing the polyline forever.
  static const _maxTrail = 250;

  final MapController _controller = MapController();
  final List<LatLng> _trail = [];
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    final first = _pointOf(widget.delivery);
    if (first != null) _trail.add(first);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Real coordinates only (null before the driver shares any) — keeps the
  /// Douala fallback out of the traveled trail.
  LatLng? _pointOf(Delivery? delivery) {
    final lat = delivery?.currentLatitude;
    final lng = delivery?.currentLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng _centerFor(Delivery? delivery) => _pointOf(delivery) ?? _fallback;

  @override
  void didUpdateWidget(LiveDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _pointOf(widget.delivery);
    final prev = _pointOf(oldWidget.delivery);
    if (next != null && next != prev) {
      // Traveled-path trail: append on change, cap the length.
      if (_trail.isEmpty || _trail.last != next) {
        _trail.add(next);
        if (_trail.length > _maxTrail) _trail.removeAt(0);
      }
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
                mapController: _controller,
                options: MapOptions(initialCenter: center, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: _tileTemplate,
                    subdomains: _tileSubdomains,
                    retinaMode: true, // pairs with {r} in the template
                    userAgentPackageName: 'com.example.green',
                  ),
                  if (_trail.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: List.unmodifiable(_trail),
                          strokeWidth: 4,
                          color: AppColors.green.withValues(alpha: 0.65),
                          // strokeCap defaults to round in flutter_map v8.
                        ),
                      ],
                    ),
                  MarkerLayer(markers: [_marker(center)]),
                  RichAttributionWidget(
                    attributions: const [
                      TextSourceAttribution(
                        'OpenStreetMap contributors © CARTO',
                      ),
                    ],
                    popupBackgroundColor: AppColors.backgroundElevated,
                    showFlutterMapAttribution: false,
                  ),
                ],
              ),
              // Transparent tap layer on top of the map. flutter_map handles
              // taps itself, so a GestureDetector around it never fires —
              // this overlay claims the tap while still letting pan/zoom
              // reach the map beneath (translucent hit test).
              if (widget.onTap != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: _liveChip(),
              ),
            ],
          ),
        ),
    );
  }

  Marker _marker(LatLng point) => Marker(
        point: point,
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing radar halo so the marker reads as LIVE.
            ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.7)
                  .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
              child: FadeTransition(
                opacity: Tween(begin: 0.45, end: 0.0).animate(_pulse),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
            // Branded pin: green circle + white ring + shadow + car icon.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
            ),
          ],
        ),
      );

  Widget _liveChip() => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
}
