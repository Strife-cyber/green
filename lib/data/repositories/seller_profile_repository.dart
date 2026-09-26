import '../models/seller_profile.dart';

/// The signed-in seller's profile + approval status (AUTH-07). Besides reading
/// the profile, sellers can update it and upload their identity documents — the
/// backend stores those URLs server-side, so the client only ever sends files.
abstract class SellerProfileRepository {
  Future<SellerProfile> me();

  /// Creates/updates the seller profile (PATCH `/seller-profiles/me`).
  /// `farmName` and `mainCategoryId` are required by the API.
  Future<void> update({
    required String farmName,
    required int mainCategoryId,
    String? farmDescription,
    String? businessLicense,
  });

  /// Uploads an identity document (multipart `file`) and returns its stored URL.
  Future<String> uploadNationalId(String filePath);

  Future<String> uploadSelfie(String filePath);

  /// Re-submits a REJECTED profile for a new review round
  /// (POST `/seller-profiles/me/resubmit`). Throws if identity documents are
  /// still missing — the profile flips back to PENDING once both are present.
  Future<void> resubmit();
}
