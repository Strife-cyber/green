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

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
        userId: json['user_id'] as String,
        farmName: json['farm_name'] as String,
        mainCategoryId: json['main_category_id'] as int?,
        businessLicense: json['business_license'] as String?,
        farmDescription: json['farm_description'] as String?,
        farmLatitude: (json['farm_latitude'] as num?)?.toDouble(),
        farmLongitude: (json['farm_longitude'] as num?)?.toDouble(),
        nationalIdUrl: json['national_id_url'] as String?,
        selfieUrl: json['selfie_url'] as String?,
        approvalStatus: SellerApprovalStatus.fromApi(json['approval_status'] as String? ?? 'pending'),
        approvedBy: json['approved_by'] as String?,
        approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'] as String) : null,
      );
}
