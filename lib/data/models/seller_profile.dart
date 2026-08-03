import 'enums.dart';

/// Seller-only data (1:1 with a User) — farm name, identity documents and the
/// admin approval gate (AUTH-01, AUTH-07, AUTH-09).
class SellerProfile {
  final String userId;
  final String farmName;
  final int? mainCategoryId;
  final String? businessLicense;

  /// Seller identity verification (AUTH-09 / §9b).
  final String? farmDescription;
  final double? farmLatitude;
  final double? farmLongitude;
  final String? nationalIdUrl;
  final String? selfieUrl;

  final SellerApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;

  const SellerProfile({
    required this.userId,
    required this.farmName,
    this.mainCategoryId,
    this.businessLicense,
    this.farmDescription,
    this.farmLatitude,
    this.farmLongitude,
    this.nationalIdUrl,
    this.selfieUrl,
    this.approvalStatus = SellerApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
  });

  bool get isApproved => approvalStatus == SellerApprovalStatus.approved;

  /// Parses the backend `SellerProfileAdminItemDto` / seller-profile DTO —
  /// camelCase, `approvalStatus` uppercase.
  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        farmName: json['farmName'] as String? ?? json['farm_name'] as String? ?? '',
        mainCategoryId: json['mainCategoryId'] as int? ?? json['main_category_id'] as int?,
        businessLicense: json['businessLicense'] as String? ?? json['business_license'] as String?,
        farmDescription: json['farmDescription'] as String? ?? json['farm_description'] as String?,
        farmLatitude: _toDoubleOrNull(json['farmLatitude'] ?? json['farm_latitude']),
        farmLongitude: _toDoubleOrNull(json['farmLongitude'] ?? json['farm_longitude']),
        nationalIdUrl: json['nationalIdUrl'] as String? ?? json['national_id_url'] as String?,
        selfieUrl: json['selfieUrl'] as String? ?? json['selfie_url'] as String?,
        approvalStatus:
            SellerApprovalStatus.fromApi(json['approvalStatus'] as String? ?? json['approval_status'] as String? ?? 'pending'),
        approvedBy: json['approvedBy'] as String? ?? json['approved_by'] as String?,
        approvedAt: _dateOrNull(json['approvedAt'] ?? json['approved_at']),
      );

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _dateOrNull(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
