import '../models/auth.dart';
import '../models/enums.dart';

/// Authentication contract (AUTH-01..08).
///
/// Screens and controllers depend on this interface only — it is backed by a
/// mock today and an Api (Dio) implementation once the backend is live.
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  /// Sends a one-time verification code to the account's email/phone (AUTH-10).
  Future<void> sendOtp(String email);

  /// Exchanges an email/phone OTP for a session (AUTH-10).
  Future<AuthSession> loginWithOtp({required String email, required String code});

  Future<AuthSession> signup(SignupInput input);

  /// Validates a persisted access token and returns the current session
  /// (AUTH-08 session restore).
  Future<AuthSession> restoreSession(String accessToken);

  Future<AuthSession> refresh(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({required String token, required String newPassword});

  Future<void> verifyEmail(String token);

  /// Resends the email-verification link to the given address (AUTH-03).
  Future<void> resendVerification(String email);

  /// One-shot `GET /auth/me` poll — true once the backend reports the current
  /// account's email as verified (D7 browse-only gate lifts).
  Future<bool> emailVerified();
}

/// Sign-up payload (AUTH-01). Sellers additionally provide farm details and
/// start with a PENDING approval status (AUTH-07).
class SignupInput {
  final UserRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String region;
  final String password;

  // Seller-only. Farm coordinates are pushed to `PATCH /seller-profiles/me`
  // during onboarding (they aren't part of the signup DTO itself). Identity
  // documents are local file paths uploaded after signup.
  final String? farmName;
  final int? mainCategoryId;
  final String? businessLicense;
  final String? farmDescription;
  final String? nationalIdUrl;
  final String? selfieUrl;
  final double? farmLatitude;
  final double? farmLongitude;

  const SignupInput({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.region,
    required this.password,
    this.farmName,
    this.mainCategoryId,
    this.businessLicense,
    this.farmDescription,
    this.nationalIdUrl,
    this.selfieUrl,
    this.farmLatitude,
    this.farmLongitude,
  });

  bool get isSeller => role == UserRole.seller;
}
