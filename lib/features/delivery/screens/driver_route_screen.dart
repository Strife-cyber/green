import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/delivery.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/driver_delivery_list_controller.dart';
import '../utils/route_planner.dart';
import '../widgets/route_map.dart';

/// Driver route planner (DRV-06): plots every open delivery as a numbered stop
/// and orders them with a nearest-neighbour heuristic from the driver's live
/// GPS fix. The route is recomputed on-device when the driver moves more than
/// ~50 m, or roughly every 10 s — never per-fix against the server.
class DriverRouteScreen extends ConsumerStatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  ConsumerState<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends ConsumerState<DriverRouteScreen> {
  /// Distance filter (m): only re-plan when the driver has meaningfully moved.
  static const _gpsMetersBetweenReplan = 50;

  /// Backstop so the route stays fresh even on a static origin.
  static const _replanInterval = Duration(seconds: 10);

  LatLng? _origin;
  StreamSubscription<Position>? _gpsSub;
  Timer? _replanTimer;

  @override
  void initState() {
    super.initState();
    _startGps();
    // Periodic backstop re-plan — cheap (few stops) and keeps the order fresh
    // as deliveries are completed elsewhere.
    _replanTimer = Timer.periodic(_replanInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _replanTimer?.cancel();
    super.dispose();
  }

  Future<void> _startGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _useFallback();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return _useFallback();
      }
      // The distance filter implements "re-run when GPS moves > ~50 m".
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _gpsMetersBetweenReplan,
        ),
      ).listen(
        (p) {
          if (mounted) setState(() => _origin = LatLng(p.latitude, p.longitude));
        },
        onError: (Object _) => _useFallback(),
        onDone: _useFallback,
      );
    } catch (_) {
      _useFallback();
    }
  }

  /// No usable GPS (permission denied, service off, platform error) — anchor
  /// the route at the city centre so planning still works offline/demo.
  void _useFallback() {
    if (mounted && _origin == null) {
      setState(() => _origin = RouteMap.fallbackOrigin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deliveries = ref.watch(driverDeliveryListControllerProvider);
    final origin = _origin ?? RouteMap.fallbackOrigin;
    final stops = deliveries.valueOrNull == null
        ? const <Delivery>[]
        : planNearestNeighbor(origin: origin, deliveries: deliveries.valueOrNull!);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Route plan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _GpsChip(live: _origin != null),
          ),
        ],
      ),
      body: deliveries.isLoading
          ? const Center(child: CircularProgressIndicator())
          : deliveries.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(deliveries.error.toString()),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref
                            .read(driverDeliveryListControllerProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : stops.isEmpty
                  ? const EmptyState(
                      icon: Icons.route_outlined,
                      title: 'No route to plan',
                      message:
                          'None of your assigned deliveries have destination '
                          'coordinates yet. Add GPS to the order address to plan a route.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _nextStopBanner(context, origin, stops.first),
                        const SizedBox(height: 16),
                        RouteMap(origin: origin, stops: stops, height: 280),
                        const SizedBox(height: 24),
                        Text(
                          'Planned stops (${stops.length})',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < stops.length; i++) ...[
                          _stopTile(context, i + 1, stops[i]),
                          if (i != stops.length - 1) const SizedBox(height: 8),
                        ],
                      ],
                    ),
    );
  }

  Widget _nextStopBanner(BuildContext context, LatLng origin, Delivery next) {
    final theme = Theme.of(context);
    final distance = haversineKm(
      origin,
      LatLng(next.destinationLatitude!, next.destinationLongitude!),
    );
    return Card(
      color: AppColors.greenDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT STOP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order ${orderReference(next.orderId)} — '
                    '${next.deliveryAddress?.label ?? 'Unlabelled'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next.deliveryAddress?.addressLine ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Text(
              distance < 1 ? '${(distance * 1000).round()} m' : '${distance.toStringAsFixed(1)} km',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopTile(BuildContext context, int number, Delivery delivery) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        title: Text(
          'Order ${orderReference(delivery.orderId)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          delivery.deliveryAddress?.addressLine ?? 'Address not set',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: delivery.isPickupConfirmed
            ? const StatusBadge(label: 'En route', color: AppColors.orange)
            : const StatusBadge(label: 'Pickup', color: AppColors.tanDark),
        onTap: () async {
          await context.push(AppRoutes.driverDelivery(delivery.id));
          if (context.mounted) {
            ref.invalidate(driverDeliveryListControllerProvider);
          }
        },
      ),
    );
  }
}

/// Small indicator of whether the route anchors on a live GPS fix or the
/// Douala fallback.
class _GpsChip extends StatelessWidget {
  final bool live;
  const _GpsChip({required this.live});

  @override
  Widget build(BuildContext context) {
    final color = live ? AppColors.green : AppColors.orange;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.my_location, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          live ? 'LIVE GPS' : 'SIMULATED',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }
}
