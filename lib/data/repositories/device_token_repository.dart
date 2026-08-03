import '../models/enums.dart';

/// Registers/deregisters this device's push token with the backend so FCM
/// pushes reach the right user (PUSH-03). The API is `POST /device-tokens`
/// (upsert) and `DELETE /device-tokens` (remove).
abstract class DeviceTokenRepository {
  Future<void> register(String token, DevicePlatform platform);
  Future<void> remove(String token);
}
