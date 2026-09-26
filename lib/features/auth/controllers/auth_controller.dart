import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/auth.dart';
import '../../../data/models/seller_profile.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/providers.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// The app's auth state — the single source of truth the router redirects on.
class AuthState {
  final AuthStatus status;
  final AuthSession? session;

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        session = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        session = null;

  const AuthState.authenticated(AuthSession this.session)
      : status = AuthStatus.authenticated;

  User? get user => session?.user;

  SellerProfile? get sellerProfile => session?.sellerProfile;
}

/// Controllers auth state: restore the persisted session on start (AUTH-08),
/// and expose login / signup / logout actions. Every successful action updates
/// [state], which the router redirect (via `routerProvider`) reacts to.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final tokens = ref.watch(tokenStorageProvider);
    final accessToken = await tokens.readAccessToken();

    // No access token at all, or an empty/blank one — there is nothing to
    // restore, so clear any half-written session deterministically.
    if (accessToken == null || accessToken.isEmpty) {
      await tokens.clearSession();
      return const AuthState.unauthenticated();
    }

    try {
      final session = await ref.read(authRepositoryProvider).restoreSession(accessToken);
      // The Dio interceptor may have refreshed the token mid-request; the repo
      // echoes back the token it was handed, so prefer whatever is on disk now
      // (keeps `session.accessToken` in sync for socket/chat consumers).
      final latestAccess = await tokens.readAccessToken() ?? accessToken;
      return AuthState.authenticated(
        latestAccess == accessToken
            ? session
            : AuthSession(
                accessToken: latestAccess,
                refreshToken: session.refreshToken,
                user: session.user,
                sellerProfile: session.sellerProfile,
              ),
      );
    } catch (_) {
      // Token stale — try the refresh token before giving up. A missing or
      // empty refresh token means the session can't be recovered: clear it
      // instead of leaving a half-restored state that redirects nowhere.
      final refreshToken = await tokens.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await tokens.clearSession();
        return const AuthState.unauthenticated();
      }
      try {
        final session = await ref.read(authRepositoryProvider).refresh(refreshToken);
        await tokens.saveSession(session);
        return AuthState.authenticated(session);
      } catch (_) {
        await tokens.clearSession();
        return const AuthState.unauthenticated();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email: email.trim(), password: password);
    await ref.read(tokenStorageProvider).saveSession(session);
    state = AsyncData(AuthState.authenticated(session));
  }

  /// Sends a one-time code to the account's email/phone (AUTH-10).
  Future<void> requestOtp(String email) {
    return ref.read(authRepositoryProvider).sendOtp(email.trim());
  }

  /// Exchanges the emailed OTP for a session, persisting it like [login].
  Future<void> loginWithOtp({required String email, required String code}) async {
    final session = await ref
        .read(authRepositoryProvider)
        .loginWithOtp(email: email.trim(), code: code.trim());
    await ref.read(tokenStorageProvider).saveSession(session);
    state = AsyncData(AuthState.authenticated(session));
  }

  Future<void> signup(SignupInput input) async {
    final session = await ref.read(authRepositoryProvider).signup(input);
    await ref.read(tokenStorageProvider).saveSession(session);
    // Sellers: signup carries only farmName + category. Push the description to
    // the profile and upload the identity documents afterwards (best-effort —
    // a failed upload must not undo a successful signup).
    if (input.isSeller) {
      await _onboardSeller(input);
    }
    state = AsyncData(AuthState.authenticated(session));
  }

  /// Best-effort post-signup seller onboarding — the staging `SignupDto`
  /// rejects `farmDescription` and document URLs, which live on the seller
  /// profile endpoints instead. Never throws.
  Future<void> _onboardSeller(SignupInput input) async {
    final profile = ref.read(sellerProfileRepositoryProvider);
    final farmName = input.farmName;
    final categoryId = input.mainCategoryId;
    if (farmName != null && categoryId != null) {
      try {
        await profile.update(
          farmName: farmName,
          mainCategoryId: categoryId,
          farmDescription: input.farmDescription,
          businessLicense: input.businessLicense,
        );
      } catch (_) {
        // Profile already created by signup; the description is best-effort.
      }
    }
    final nationalId = input.nationalIdUrl;
    if (nationalId != null && nationalId.isNotEmpty) {
      try {
        await profile.uploadNationalId(nationalId);
      } catch (_) {
        // Documents can be re-uploaded later from the profile screen.
      }
    }
    final selfie = input.selfieUrl;
    if (selfie != null && selfie.isNotEmpty) {
      try {
        await profile.uploadSelfie(selfie);
      } catch (_) {
        // Documents can be re-uploaded later from the profile screen.
      }
    }
  }

  Future<void> logout() async {
    final tokens = ref.read(tokenStorageProvider);
    // Deregister the FCM token while the access token is still valid — the
    // DELETE needs the JWT, which clearSession()/server logout would revoke.
    if (PushService.instance.isReady) {
      try {
        await PushService.instance.deregisterToken();
      } catch (_) {
        // Best-effort; never block logout.
      }
    }
    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } catch (_) {
        // Best-effort server-side logout; always clear locally.
      }
    }
    await tokens.clearSession();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> forgotPassword(String email) {
    return ref.read(authRepositoryProvider).forgotPassword(email.trim());
  }

  Future<void> resetPassword({required String token, required String newPassword}) {
    return ref.read(authRepositoryProvider).resetPassword(token: token.trim(), newPassword: newPassword);
  }

  /// Re-sends the email-verification link (AUTH-03).
  Future<void> resendVerification(String email) {
    return ref.read(authRepositoryProvider).resendVerification(email.trim());
  }

  /// Consumes the emailed verification token (AUTH-03, deep link
  /// `/verify-email?token=…`) — validates it server-side, then the next
  /// [checkEmailVerification] poll flips the session.
  Future<void> verifyEmailToken(String token) {
    return ref.read(authRepositoryProvider).verifyEmail(token.trim());
  }

  /// Re-fetches the current session (used by the "I've verified — check
  /// status" affordance on the verification screen). If the backend now reports
  /// `emailVerified: true`, the router's redirect can let the user through.
  Future<void> refreshSession() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Token may be stale — the user can sign in again.
    }
  }

  /// One-shot "did they verify?" check — a single `GET /auth/me` poll per tap,
  /// NOT a provider invalidate (a full rebuild briefly reports
  /// [AuthStatus.unknown], which bounced the router through splash). When the
  /// backend reports verified, the session's user is updated in place so the
  /// browse-only banner lifts and order actions unlock.
  Future<bool> checkEmailVerification() async {
    final session = state.valueOrNull?.session;
    if (session == null) return false;
    try {
      final verified = await ref.read(authRepositoryProvider).emailVerified();
      if (!verified) return false;
      state = AsyncData(
        AuthState.authenticated(
          AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            user: session.user.copyWith(emailVerified: true),
            sellerProfile: session.sellerProfile,
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user's id, or null while unauthenticated. User-scoped
/// providers watch THIS (not the full auth state) so they only rebuild on an
/// actual account switch — logout, login, session expiry — instead of
/// refetching on every auth emission (e.g. the verify banner's status check).
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(
    authControllerProvider.select((a) => a.valueOrNull?.user?.id),
  ),
);
