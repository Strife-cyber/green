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

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as String,
        orderId: json['order_id'] as String? ?? '',
        driverId: json['driver_id'] as String?,
        driverName: json['driver_name'] as String?,
        assignedAt: json['assigned_at'] != null ? DateTime.tryParse(json['assigned_at'] as String) : null,
        pickupConfirmedAt: json['pickup_confirmed_at'] != null
            ? DateTime.tryParse(json['pickup_confirmed_at'] as String)
            : null,
        deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'] as String) : null,
        currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
        currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
        locationUpdatedAt: json['location_updated_at'] != null
            ? DateTime.tryParse(json['location_updated_at'] as String)
            : null,
      );
}
