import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/auth.dart';

/// Persistence for the auth session (AUTH-08).
///
/// Abstract so tests can swap in an in-memory implementation without touching
/// the secure-storage platform channel.
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
}

/// Secure, platform-encrypted storage for tokens (keystore/keychain).
class SecureTokenStorage implements TokenStorage {
  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _kAccess, value: session.accessToken);
    await _storage.write(key: _kRefresh, value: session.refreshToken);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());
