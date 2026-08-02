import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage-backed wallet PIN (PAY-10).
///
/// Only a salted SHA-256 hash of the PIN is ever persisted — never the
/// plaintext. Verification is client-side for the demo; it moves server-side
/// (the PIN is submitted over the payment API) at the hand-off.
abstract class WalletPinService {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verify(String pin);
}

/// [FlutterSecureStorage] implementation (keystore/keychain encrypted).
class SecureWalletPinService implements WalletPinService {
  static const _kSalt = 'wallet_pin.salt';
  static const _kHash = 'wallet_pin.hash';

  final FlutterSecureStorage _storage;

  SecureWalletPinService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _kHash);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _hash(salt, pin));
  }

  @override
  Future<bool> verify(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final hash = await _storage.read(key: _kHash);
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  /// 16 random bytes as hex — a fresh salt per PIN, so identical PINs hash to
  /// different values.
  static String _randomSalt() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt$pin')).toString();
}

/// Wired over secure storage; tests can override with an in-memory fake.
final walletPinServiceProvider = Provider<WalletPinService>((ref) => SecureWalletPinService());
