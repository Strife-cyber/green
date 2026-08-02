import '../models/seller_profile.dart';

/// The signed-in seller's profile + approval status (AUTH-07).
abstract class SellerProfileRepository {
  Future<SellerProfile> me();
}
