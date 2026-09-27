import 'address.dart';
import 'enums.dart';

/// A delivery assignment with live driver position (DEL-02/03, DRV-03/04).
class Delivery {
  final String id;
  final String orderId;

  /// The selling farm this delivery picks up from. Not exposed by the live
  /// delivery payload (the nested order summary only carries id/status), so
  /// the mock enriches it from the linked order for the driver's "Pick up"
  /// task line; null on live responses, where the driver card falls back to a
  /// generic label.
  final String? sellerName;

  final String? driverId;
  final String? driverName;

  /// Driver contact/vehicle extras — present when the backend enriches the
  /// delivery with driver details (tracker card). Null when not sent.
  final String? driverPhone;
  final String? driverVehicle;
  final double? driverRating;

  /// Buyer details for the driver's task card / code hand-off — from the
  /// nested `order` (`buyer: {firstName, lastName, phone}`).
  final String? buyerId;
  final String? buyerName;
  final String? buyerPhone;

  /// Delivery fee on the linked order (FCFA) — feeds the driver's "My day"
  /// total when the backend reports it.
  final int? deliveryFee;
  final DateTime? assignedAt;
  final DateTime? pickupConfirmedAt;
  final DateTime? deliveredAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? locationUpdatedAt;

  /// True once a confirmation code has been issued for the hand-off (DEL-07).
  /// The backend may report this as `confirmationCodeIssued`, `codeIssuedAt`
  /// or `confirmationCodeSent` depending on endpoint/version — we accept all
  /// three. No separate resend endpoint exists; the driver issues the code
  /// on the delivery detail flow.
  final bool confirmationCodeIssued;

  /// The order's destination (DRV-06). The backend nests it under `order` as
  /// `deliveryAddress` with WGS84 `latitude`/`longitude` (may be null when the
  /// order has no saved address). Drives the route planner.
  final Address? deliveryAddress;

  /// The linked order's lifecycle status as reported by the backend delivery
  /// payload (`orderStatus` at the top level, or `order.status` on the list
  /// item). Null on responses predating the field.
  final OrderStatus? orderStatus;

  /// True when the order total is above the code-required threshold
  /// (> 25 000 FCFA): the buyer must enter the emailed 6-digit code to complete
  /// the hand-off. When false, the buyer confirms with a one-tap "Got it"
  /// (`confirm` with a null code).
  final bool codeRequired;

  const Delivery({
    required this.id,
    required this.orderId,
    this.sellerName,
    this.driverId,
    this.driverName,
    this.assignedAt,
    this.pickupConfirmedAt,
    this.deliveredAt,
    this.currentLatitude,
    this.currentLongitude,
    this.locationUpdatedAt,
    this.driverPhone,
    this.driverVehicle,
    this.driverRating,
    this.buyerId,
    this.buyerName,
    this.buyerPhone,
    this.deliveryFee,
    this.deliveryAddress,
    this.confirmationCodeIssued = false,
    this.orderStatus,
    this.codeRequired = false,
  });

  bool get isPickupConfirmed => pickupConfirmedAt != null;
  bool get isDelivered => deliveredAt != null;

  /// True once the driver has picked up (order SHIPPED) but the buyer has not
  /// confirmed yet — the window where the buyer can tap "Got it". The backend
  /// exposes no explicit "arrived" flag, so pickup-while-undelivered is the
  /// closest reliable signal (the buyer's one-tap is idempotent regardless).
  bool get isAwaitingBuyer => isPickupConfirmed && !isDelivered;

  /// Destination coordinates, when the order's saved address has them.
  double? get destinationLatitude => deliveryAddress?.latitude;
  double? get destinationLongitude => deliveryAddress?.longitude;

  /// True when this delivery has a drivable destination (a coordinate is a
  /// requirement for route planning — a region name alone isn't).
  bool get hasDestination => destinationLatitude != null && destinationLongitude != null;

  /// Parses the backend `DeliveryListItemDto` — camelCase.
  factory Delivery.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final driver = json['driver'];
    final buyer = order is Map<String, dynamic> ? order['buyer'] : null;
    return Delivery(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
      sellerName: json['sellerName'] as String? ??
          json['seller_name'] as String? ??
          (order is Map<String, dynamic> ? order['sellerName'] as String? : null),
      driverId: json['driverId'] as String? ?? json['driver_id'] as String?,
      driverName: json['driverName'] as String? ??
          json['driver_name'] as String? ??
          _fullName(driver),
      driverPhone: json['driverPhone'] as String? ??
          (driver is Map<String, dynamic> ? driver['phone'] as String? : null),
      driverVehicle: json['driverVehicle'] as String? ??
          json['vehicle'] as String? ??
          (driver is Map<String, dynamic> ? driver['vehicle'] as String? : null),
      driverRating: _toDoubleOrNull(json['driverRating'] ??
          (driver is Map<String, dynamic> ? driver['rating'] : null)),
      buyerId: buyer is Map<String, dynamic> ? buyer['id'] as String? : null,
      buyerName: _fullName(buyer),
      buyerPhone: buyer is Map<String, dynamic> ? buyer['phone'] as String? : null,
      deliveryFee: _toIntOrNull(json['deliveryFee'] ??
          (order is Map<String, dynamic> ? order['deliveryFee'] : null)),
      assignedAt: _dateOrNull(json['assignedAt'] ?? json['assigned_at']),
      pickupConfirmedAt: _dateOrNull(json['pickupConfirmedAt'] ?? json['pickup_confirmed_at']),
      deliveredAt: _dateOrNull(json['deliveredAt'] ?? json['delivered_at']),
      currentLatitude: _toDoubleOrNull(json['currentLatitude'] ?? json['current_latitude']),
      currentLongitude: _toDoubleOrNull(json['currentLongitude'] ?? json['current_longitude']),
      locationUpdatedAt: _dateOrNull(json['locationUpdatedAt'] ?? json['location_updated_at']),
      deliveryAddress: _deliveryAddressFrom(json['order'] ?? json),
      confirmationCodeIssued: json['confirmationCodeIssued'] == true ||
          json['codeIssuedAt'] != null ||
          json['confirmationCodeSent'] == true,
      orderStatus: _orderStatusFrom(json['orderStatus'], order),
      codeRequired: json['codeRequired'] == true ||
          (order is Map<String, dynamic> && order['codeRequired'] == true),
    );
  }

  Delivery copyWith({
    String? sellerName,
    String? driverId,
    String? driverName,
    DateTime? assignedAt,
    DateTime? pickupConfirmedAt,
    DateTime? deliveredAt,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? locationUpdatedAt,
    bool? confirmationCodeIssued,
    Address? deliveryAddress,
    OrderStatus? orderStatus,
    bool? codeRequired,
  }) =>
      Delivery(
        id: id,
        orderId: orderId,
        sellerName: sellerName ?? this.sellerName,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        assignedAt: assignedAt ?? this.assignedAt,
        pickupConfirmedAt: pickupConfirmedAt ?? this.pickupConfirmedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        currentLatitude: currentLatitude ?? this.currentLatitude,
        currentLongitude: currentLongitude ?? this.currentLongitude,
        locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
        confirmationCodeIssued: confirmationCodeIssued ?? this.confirmationCodeIssued,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        orderStatus: orderStatus ?? this.orderStatus,
        codeRequired: codeRequired ?? this.codeRequired,
      );

  /// `{firstName,lastName}` → "First Last", null when the object is absent or
  /// both parts are blank.
  static String? _fullName(dynamic user) {
    if (user is! Map<String, dynamic>) return null;
    final first = (user['firstName'] as String? ?? '').trim();
    final last = (user['lastName'] as String? ?? '').trim();
    final full = '$first $last'.trim();
    return full.isEmpty ? null : full;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round();
  }

  static OrderStatus? _orderStatusFrom(Object? topLevel, Object? nested) {
    final raw = topLevel ?? (nested is Map<String, dynamic> ? nested['status'] : null);
    if (raw == null) return null;
    return OrderStatus.fromApi(raw.toString());
  }

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
