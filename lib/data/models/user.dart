import 'enums.dart';

/// A platform account (AUTH-01). `role` decides which home the user lands on.
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? region;

  /// Farm/home coordinates (DEL-04). Null until captured.
  final double? latitude;
  final double? longitude;

  /// Unverified users are browse-only until they verify (D7, AUTH-03).
  final bool emailVerified;

  final DateTime? createdAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.region,
    this.latitude,
    this.longitude,
    this.emailVerified = false,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserRole.fromApi(json['role'] as String? ?? 'buyer'),
        region: json['region'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        emailVerified: json['email_verified'] as bool? ?? false,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'role': role.name,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
        'email_verified': emailVerified,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
