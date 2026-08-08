import 'address.dart';

/// A delivery assignment with live driver position (DEL-02/03, DRV-03/04).
class Delivery {
  final String id;
  final String orderId;
  final String? driverId;
  final String? driverName;
  final DateTime? assignedAt;
  final DateTime? pickupConfirmedAt;
  final DateTime? deliveredAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? locationUpdatedAt;

  /// The order's destination (DRV-06). The backend nests it under `order` as
  /// `deliveryAddress` with WGS84 `latitude`/`longitude` (may be null when the
  /// order has no saved address). Drives the route planner.
  final Address? deliveryAddress;

  const Delivery({
    required this.id,
    required this.orderId,
    this.driverId,
    this.driverName,
    this.assignedAt,
    this.pickupConfirmedAt,
    this.deliveredAt,
    this.currentLatitude,
    this.currentLongitude,
    this.locationUpdatedAt,
    this.deliveryAddress,
  });

  bool get isPickupConfirmed => pickupConfirmedAt != null;
  bool get isDelivered => deliveredAt != null;

  /// Destination coordinates, when the order's saved address has them.
  double? get destinationLatitude => deliveryAddress?.latitude;
  double? get destinationLongitude => deliveryAddress?.longitude;

  /// True when this delivery has a drivable destination (a coordinate is a
  /// requirement for route planning — a region name alone isn't).
  bool get hasDestination => destinationLatitude != null && destinationLongitude != null;

  /// Parses the backend `DeliveryListItemDto` — camelCase.
  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as String,
        orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
        driverId: json['driverId'] as String? ?? json['driver_id'] as String?,
        driverName: json['driverName'] as String? ?? json['driver_name'] as String?,
        assignedAt: _dateOrNull(json['assignedAt'] ?? json['assigned_at']),
        pickupConfirmedAt: _dateOrNull(json['pickupConfirmedAt'] ?? json['pickup_confirmed_at']),
        deliveredAt: _dateOrNull(json['deliveredAt'] ?? json['delivered_at']),
        currentLatitude: _toDoubleOrNull(json['currentLatitude'] ?? json['current_latitude']),
        currentLongitude: _toDoubleOrNull(json['currentLongitude'] ?? json['current_longitude']),
        locationUpdatedAt: _dateOrNull(json['locationUpdatedAt'] ?? json['location_updated_at']),
        deliveryAddress: _deliveryAddressFrom(json['order'] ?? json),
      );

  /// The destination lives under the nested `order` object in the delivery
  /// payload; fall back to a flat `deliveryAddress` for older responses.
  static Address? _deliveryAddressFrom(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final address = raw['deliveryAddress'] ?? raw['delivery_address'];
    if (address is! Map<String, dynamic>) return null;
    try {
      return Address.fromJson(address);
    } catch (_) {
      return null; // Malformed destination — treat as no address.
    }
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _dateOrNull(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
