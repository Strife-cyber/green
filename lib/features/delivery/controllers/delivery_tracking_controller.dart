import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../data/models/delivery.dart';
import '../../../data/repositories/providers.dart';

/// Identifies the delivery to track: the driver knows its delivery id, while
/// a buyer/seller only knows the order id.
class DeliveryTrackingRequest {
  final String? deliveryId;
  final String? orderId;

  const DeliveryTrackingRequest({this.deliveryId, this.orderId});

  @override
  bool operator ==(Object other) =>
      other is DeliveryTrackingRequest &&
      other.deliveryId == deliveryId &&
      other.orderId == orderId;

  @override
  int get hashCode => Object.hash(deliveryId, orderId);
}

/// Latest known delivery position and status for live tracking (DEL-04/DRV-04).
class DeliveryTrackingState {
  final Delivery? delivery;
  final bool loading;
  final String? error;

  /// True while the driver is publishing the mock position route.
  final bool publishing;

  const DeliveryTrackingState({
    this.delivery,
    this.loading = false,
    this.error,
    this.publishing = false,
  });
}

/// Tracks a delivery's live position. The latest [Delivery] is loaded from the
/// repository and polled every few seconds so pickup/deliver status stays
/// fresh; `delivery.locationUpdated` socket events for the matching delivery
/// are merged in as they arrive. The driver can also call [startPublishing] to
/// walk a fixed mock route, keeping the demo visible before the backend socket
/// is live (the mock socket connects to nothing, so all calls are guarded).
class DeliveryTrackingController
    extends FamilyNotifier<DeliveryTrackingState, DeliveryTrackingRequest> {
  static const _pollInterval = Duration(seconds: 5);
  static const _publishInterval = Duration(seconds: 2);

  /// Fixed mock route around Douala — stepped once per publish tick.
  static const _route = <LatLng>[
    LatLng(4.0430, 9.7600),
    LatLng(4.0445, 9.7635),
    LatLng(4.0460, 9.7670),
    LatLng(4.0485, 9.7700),
    LatLng(4.0510, 9.7735),
  ];

  Timer? _pollTimer;
  Timer? _publishTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  int _routeIndex = 0;
  bool _disposed = false;

  @override
  DeliveryTrackingState build(DeliveryTrackingRequest request) {
    _disposed = false;
    final socket = ref.read(socketServiceProvider);
    _socketSub = socket.events('delivery.locationUpdated').listen(_mergeSocketEvent);
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_refresh()));
    ref.onDispose(() {
      _disposed = true;
      _dispose();
    });
    unawaited(_refresh());
    return const DeliveryTrackingState(loading: true);
  }

  /// Re-loads the delivery from the repository (initial load, poll and after
  /// a pickup/deliver action).
  Future<void> refreshNow() => _refresh();

  /// Begins publishing the driver's mock position every few seconds, updating
  /// local state and broadcasting `delivery.locationUpdated` to followers.
  void startPublishing() {
    if (state.publishing) return;
    state = DeliveryTrackingState(delivery: state.delivery, publishing: true);
    _tick();
    _publishTimer?.cancel();
    _publishTimer = Timer.periodic(_publishInterval, (_) => _tick());
  }

  /// Stops publishing the mock position (e.g. once delivered).
  void stopPublishing() {
    _publishTimer?.cancel();
    _publishTimer = null;
    if (!state.publishing) return;
    state = DeliveryTrackingState(delivery: state.delivery, publishing: false);
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final request = arg;
      final Delivery fresh;
      if (request.deliveryId != null) {
        fresh = await repo.get(request.deliveryId!);
      } else {
        final all = await repo.driverOrders();
        fresh = all.firstWhere(
          (d) => d.orderId == request.orderId,
          orElse: () => throw StateError('No delivery for order ${request.orderId}'),
        );
      }
      if (_disposed) return;
      // While publishing, keep the driver's locally-stepped coordinates and
      // only take the status fields from the repository.
      final keepCoords = state.publishing && state.delivery != null;
      state = DeliveryTrackingState(
        delivery: keepCoords
            ? _withCoords(
                fresh,
                state.delivery!.currentLatitude,
                state.delivery!.currentLongitude,
                state.delivery!.locationUpdatedAt,
              )
            : fresh,
        publishing: state.publishing,
      );
    } catch (error) {
      if (_disposed) return;
      state = DeliveryTrackingState(error: error.toString(), publishing: state.publishing);
    }
  }

  void _mergeSocketEvent(Map<String, dynamic> data) {
    try {
      final current = state.delivery;
      if (current == null) return;
      final deliveryId = data['deliveryId'] as String?;
      final orderId = data['orderId'] as String?;
      final matches = (deliveryId != null && deliveryId == current.id) ||
          (orderId != null && orderId == current.orderId);
      if (!matches) return;
      final lat = (data['currentLatitude'] as num?)?.toDouble();
      final lng = (data['currentLongitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final updatedAt = DateTime.tryParse(data['locationUpdatedAt'] as String? ?? '');
      state = DeliveryTrackingState(
        delivery: _withCoords(current, lat, lng, updatedAt ?? DateTime.now()),
        publishing: state.publishing,
      );
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  void _tick() {
    final current = state.delivery;
    if (current == null || current.isDelivered) {
      stopPublishing();
      return;
    }
    final point = _route[_routeIndex % _route.length];
    _routeIndex++;
    final updatedAt = DateTime.now();
    final updated = _withCoords(current, point.latitude, point.longitude, updatedAt);
    state = DeliveryTrackingState(delivery: updated, publishing: true);
    // Broadcast so buyers/sellers following the order see the movement. The
    // mock socket connects to nothing in dev, so this is a guarded no-op.
    try {
      ref.read(socketServiceProvider).emit('delivery.locationUpdated', {
        'deliveryId': updated.id,
        'orderId': updated.orderId,
        'currentLatitude': updated.currentLatitude,
        'currentLongitude': updated.currentLongitude,
        'locationUpdatedAt': updatedAt.toIso8601String(),
      });
    } catch (_) {
      // Socket unavailable — ignore.
    }
  }

  void _dispose() {
    _pollTimer?.cancel();
    _publishTimer?.cancel();
    _socketSub?.cancel();
  }

  Delivery _withCoords(Delivery d, double? lat, double? lng, DateTime? at) => Delivery(
        id: d.id,
        orderId: d.orderId,
        driverId: d.driverId,
        driverName: d.driverName,
        assignedAt: d.assignedAt,
        pickupConfirmedAt: d.pickupConfirmedAt,
        deliveredAt: d.deliveredAt,
        currentLatitude: lat ?? d.currentLatitude,
        currentLongitude: lng ?? d.currentLongitude,
        locationUpdatedAt: at ?? d.locationUpdatedAt,
      );
}

final deliveryTrackingControllerProvider =
    NotifierProvider.family<DeliveryTrackingController, DeliveryTrackingState,
        DeliveryTrackingRequest>(DeliveryTrackingController.new);
