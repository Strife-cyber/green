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

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        recipientName: json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        region: json['region'] as String? ?? '',
        addressLine: json['address_line'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['is_default'] as bool? ?? false,
      );
}
