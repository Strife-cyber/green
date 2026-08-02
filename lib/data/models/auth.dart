import 'seller_profile.dart';
import 'user.dart';

/// A valid session: JWT access + refresh tokens plus the authenticated user.
///
/// [sellerProfile] is populated for sellers (used for the approval banner);
/// the backend may expose it via a separate profile fetch — see the Swagger
/// hand-off checklist.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final User user;
  final SellerProfile? sellerProfile;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.sellerProfile,
  });
}
