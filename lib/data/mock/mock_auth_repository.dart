import '../models/auth.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'mock_data.dart';

/// Mock auth — simulates network latency and returns seeded demo sessions so
/// the whole auth flow (login → role redirect) is buildable before the backend
/// is live. Swapped for an Api implementation at hand-off.
class MockAuthRepository implements AuthRepository {
  static const _latency = Duration(milliseconds: 500);

  /// Demo-only OTP code. The real backend sends a 6-digit code by email/phone;
  /// the mock accepts this fixed value so the flow is exercisable pre-hand-off.
  static const demoOtpCode = '123456';

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    await Future<void>.delayed(_latency);
    return _sessionFor(email, approvedSeller: true);
  }

  @override
  Future<void> sendOtp(String email) async {
    await Future<void>.delayed(_latency);
    // Simulates the backend emailing/Phoning a 6-digit code.
  }

  @override
  Future<AuthSession> loginWithOtp({required String email, required String code}) async {
    await Future<void>.delayed(_latency);
    if (code.trim() != demoOtpCode) {
      throw StateError('Invalid verification code.');
    }
    return _sessionFor(email, approvedSeller: true);
  }

  @override
  Future<AuthSession> signup(SignupInput input) async {
    await Future<void>.delayed(_latency);
    // A signed-up seller is created with status PENDING (AUTH-07).
    final user = User(
      id: 'u-${input.email.hashCode.abs()}',
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      phone: input.phone,
      role: input.role,
      region: input.region,
      emailVerified: false, // verification email would be sent (AUTH-03)
    );
    return AuthSession(
      accessToken: 'mock-access-${user.id}',
      refreshToken: 'mock-refresh-${user.id}',
      user: user,
      sellerProfile: input.isSeller
          ? MockData.pendingSellerProfile(
              user.id,
              input.farmName ?? '',
              mainCategoryId: input.mainCategoryId,
              businessLicense: input.businessLicense,
              farmDescription: input.farmDescription,
              farmLatitude: input.farmLatitude,
              farmLongitude: input.farmLongitude,
              nationalIdUrl: input.nationalIdUrl,
              selfieUrl: input.selfieUrl,
            )
          : null,
    );
  }

  @override
  Future<AuthSession> restoreSession(String accessToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Mock tokens embed the user id: `mock-access-<id>`.
    final id = accessToken.replaceFirst('mock-access-', '');
    final email = switch (id) {
      'u-buyer-1' => 'buyer@greenish.cm',
      'u-seller-1' => 'seller@greenish.cm',
      'u-admin-1' => 'admin@greenish.cm',
      'u-driver-1' => 'driver@greenish.cm',
      _ => 'buyer@greenish.cm',
    };
    return _sessionFor(email, approvedSeller: true);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return restoreSession(refreshToken.replaceFirst('mock-refresh-', 'mock-access-'));
  }

  @override
  Future<void> logout(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // Nothing to invalidate in the mock.
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Simulates sending a reset link.
  }

  @override
  Future<void> resetPassword({required String token, required String newPassword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> verifyEmail(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  AuthSession _sessionFor(String email, {required bool approvedSeller}) {
    final user = MockData.userForEmail(email);
    return AuthSession(
      accessToken: 'mock-access-${user.id}',
      refreshToken: 'mock-refresh-${user.id}',
      user: user,
      sellerProfile: user.role == UserRole.seller ? MockData.sellerProfile : null,
    );
  }
}
