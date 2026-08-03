import 'enums.dart';

/// A platform account (AUTH-01). `role` decides which home the user lands on.
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;

  /// Admin sub-role (SUPER_ADMIN/FINANCE/SUPPORT/COMPLIANCE) — only populated
  /// for ADMIN accounts.
  final AdminRole? adminRole;

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
    this.adminRole,
    this.region,
    this.latitude,
    this.longitude,
    this.emailVerified = false,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  /// Parses the backend user DTO — all fields are camelCase (`firstName`,
  /// `emailVerified`, `adminRole`, …).
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
        lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        role: UserRole.fromApi(json['role'] as String? ?? 'buyer'),
        adminRole: AdminRole.fromApi(json['adminRole'] as String?),
        region: json['region'] as String?,
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        emailVerified: json['emailVerified'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role.apiValue,
        if (adminRole != null) 'adminRole': adminRole!.apiValue,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
        'emailVerified': emailVerified,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
