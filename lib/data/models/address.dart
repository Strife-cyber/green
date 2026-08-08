/// A saved delivery address (BUY-07/08).
class Address {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String region;
  final String addressLine;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.region,
    required this.addressLine,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  /// Parses the backend `CreateAddressDto` response — camelCase. Coordinates
  /// are returned as decimal strings by the API. `id` may be absent on legacy
  /// payloads (e.g. a coordinate-only delivery destination) — default to ''.
  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        recipientName: json['recipientName'] as String? ?? json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        region: json['region'] as String? ?? '',
        addressLine: json['addressLine'] as String? ?? json['address_line'] as String? ?? '',
        latitude: _toDoubleOrNull(json['latitude']),
        longitude: _toDoubleOrNull(json['longitude']),
        isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      );

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
