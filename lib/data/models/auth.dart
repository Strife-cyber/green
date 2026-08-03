import 'seller_profile.dart';
import 'user.dart';

/// A valid session: JWT access + refresh tokens plus the authenticated user.
///
/// [sellerProfile] is populated for sellers (used for the approval banner);
/// the API exposes it via a separate profile fetch (`GET /seller-profiles/me`).
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

  /// Parses the auth token-pair envelope `{ user, accessToken, refreshToken }`
  /// returned by signup, login, refresh and OTP login.
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        user: User.fromJson(
          json['user'] is Map<String, dynamic>
              ? json['user'] as Map<String, dynamic>
              : const <String, dynamic>{},
        ),
      );
}
