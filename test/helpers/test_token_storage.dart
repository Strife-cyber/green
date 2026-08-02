import 'package:green/core/storage/token_storage.dart';
import 'package:green/data/models/auth.dart';

/// In-memory [TokenStorage] for tests — avoids the secure-storage platform
/// channel entirely.
class InMemoryTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> saveSession(AuthSession session) async {
    _access = session.accessToken;
    _refresh = session.refreshToken;
  }

  @override
  Future<void> clearSession() async {
    _access = null;
    _refresh = null;
  }
}
