import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

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

  /// True while the driver is publishing live position (device GPS, or the
  /// simulated route fallback when GPS isn't available).
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
/// fresh; `location:updated` socket events for the matching delivery are
/// merged in as they arrive. The driver can call [startPublishing] to share
/// their device GPS, falling back to a simulated Douala route when location
/// isn't available so the demo still moves (all socket calls are guarded).
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
  StreamSubscription<Position>? _gpsSub;

  /// Cached delivery id once it's resolved through the order — the 5s status
  /// poll then hits `GET /deliveries/{id}` directly instead of re-fetching the
  /// order every tick. Position still streams over the socket; the poll only
  /// keeps status (pickup/delivered) fresh.
  String? _resolvedDeliveryId;
  int _routeIndex = 0;
  bool _disposed = false;

  @override
  DeliveryTrackingState build(DeliveryTrackingRequest request) {
    _disposed = false;
    // Scoped to the signed-in user: the rebuild on logout/login disposes the
    // poller/socket and a signed-out tracker stays idle instead of polling
    // with a dead token.
    if (ref.watch(currentUserIdProvider) == null) {
      return const DeliveryTrackingState();
    }
    final socket = ref.read(socketServiceProvider);
    // Connect (awaiting session restore on cold start, so the token is never
    // empty) and join the deliveries room — rooms are re-joined automatically
    // on any reconnect.
    unawaited(socket.connectWhenAuthed(ref, namespace: SocketService.deliveriesNamespace));
    if (request.deliveryId != null) {
      socket.joinRoom(SocketService.deliveriesNamespace, {'deliveryId': request.deliveryId!});
    }
    _socketSub = socket
        .events('location:updated', namespace: SocketService.deliveriesNamespace)
        .listen(_mergeSocketEvent);
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

  /// Begins publishing the driver's live device GPS, updating local state and
  /// broadcasting `location:update` to followers. When location permission is
  /// denied, GPS is off or the stream errors, it falls back to the simulated
  /// Douala route so the demo never breaks.
  Future<void> startPublishing() async {
    if (state.publishing) return;
    state = DeliveryTrackingState(delivery: state.delivery, publishing: true);
    _publishTimer?.cancel();
    _gpsSub?.cancel();

    if (!await _locationPermissionGranted()) {
      if (_disposed) return;
      _startSimulatedRoute();
      return;
    }
    if (_disposed) return;
    try {
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // meters — trims jitter while still following roads
        ),
      ).listen(
        _onGpsPosition,
        onError: (Object _) => _startSimulatedRoute(),
        onDone: _startSimulatedRoute,
      );
    } catch (_) {
      _startSimulatedRoute();
    }
  }

  /// Stops publishing position (GPS stream + any fallback timer).
  void stopPublishing() {
    _publishTimer?.cancel();
    _publishTimer = null;
    _gpsSub?.cancel();
    _gpsSub = null;
    if (!state.publishing) return;
    state = DeliveryTrackingState(delivery: state.delivery, publishing: false);
  }

  Future<bool> _locationPermissionGranted() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  void _onGpsPosition(Position position) {
    final current = state.delivery;
    if (current == null || current.isDelivered) {
      stopPublishing();
      return;
    }
    final updated = _withCoords(
      current,
      position.latitude,
      position.longitude,
      position.timestamp.toLocal(),
    );
    state = DeliveryTrackingState(delivery: updated, publishing: true);
    _emitLocation(updated);
  }

  /// Steps the hardcoded Douala route — used only when real GPS is
  /// unavailable, so the tracking demo still moves.
  void _startSimulatedRoute() {
    if (!state.publishing) return; // already stopped
    _gpsSub?.cancel();
    _gpsSub = null;
    _routeIndex = 0;
    _publishTimer?.cancel();
    _tick();
    _publishTimer = Timer.periodic(_publishInterval, (_) => _tick());
  }

  /// Broadcasts a position so buyers/sellers following the order see movement
  /// (real protocol: `location:update` with lat/lng).
  void _emitLocation(Delivery updated) {
    try {
      ref.read(socketServiceProvider).emit(
            'location:update',
            {
              'deliveryId': updated.id,
              'latitude': updated.currentLatitude,
              'longitude': updated.currentLongitude,
            },
            namespace: SocketService.deliveriesNamespace,
          );
    } catch (_) {
      // Socket unavailable — ignore.
    }
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final request = arg;
      final Delivery fresh;
      if (request.deliveryId != null) {
        _resolvedDeliveryId = request.deliveryId;
        fresh = await repo.get(request.deliveryId!);
      } else if (_resolvedDeliveryId != null) {
        // Already resolved through the order — skip the order lookup on polls.
        fresh = await repo.get(_resolvedDeliveryId!);
      } else {
        // `GET /deliveries/driver` is driver-only — a buyer/seller who opens
        // tracking would 403. Resolve their delivery through the order instead:
        // the order payload embeds the assigned delivery's id (DEL-02), and
        // `GET /deliveries/{id}` is visible to the order's buyer/seller.
        final role = ref.read(authControllerProvider).valueOrNull?.user?.role;
        if (role == UserRole.driver) {
          final all = await repo.driverOrders();
          final driverDelivery = all.firstWhere(
            (d) => d.orderId == request.orderId,
            orElse: () => throw StateError('No delivery for order ${request.orderId}'),
          );
          _resolvedDeliveryId = driverDelivery.id;
          fresh = driverDelivery;
        } else {
          final order = await ref.read(orderRepositoryProvider).get(request.orderId!);
          final deliveryId = order.deliveryId;
          if (deliveryId == null) {
            // No driver assigned yet — let the screen show its "not assigned"
            // empty state rather than a confusing load error.
            state = DeliveryTrackingState(publishing: state.publishing);
            return;
          }
          _resolvedDeliveryId = deliveryId;
          fresh = await repo.get(deliveryId);
        }
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

  /// Merges a `location:updated` payload `{ deliveryId, latitude, longitude,
  /// updatedAt }` into local state.
  void _mergeSocketEvent(Map<String, dynamic> data) {
    try {
      final current = state.delivery;
      if (current == null) return;
      final deliveryId = data['deliveryId'] as String?;
      if (deliveryId == null || deliveryId != current.id) return;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final updatedAt = DateTime.tryParse(data['updatedAt'] as String? ?? '');
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
    _emitLocation(updated);
  }

  void _dispose() {
    _pollTimer?.cancel();
    _publishTimer?.cancel();
    _gpsSub?.cancel();
    _socketSub?.cancel();
  }

  Delivery _withCoords(Delivery d, double? lat, double? lng, DateTime? at) => d.copyWith(
        currentLatitude: lat ?? d.currentLatitude,
        currentLongitude: lng ?? d.currentLongitude,
        locationUpdatedAt: at ?? d.locationUpdatedAt,
      );
}

final deliveryTrackingControllerProvider =
    NotifierProvider.family<DeliveryTrackingController, DeliveryTrackingState,
        DeliveryTrackingRequest>(DeliveryTrackingController.new);
