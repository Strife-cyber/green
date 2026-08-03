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
  });

  bool get isPickupConfirmed => pickupConfirmedAt != null;
  bool get isDelivered => deliveredAt != null;

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
      );

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _dateOrNull(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
