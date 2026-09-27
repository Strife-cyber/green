import '../models/platform_config.dart';

/// Runtime-tunable business parameters (`GET /platform-config/{key}`) —
/// delivery fee, withdrawal minimum, commission rate (ADM-11). A null result
/// means the key is not configured; callers apply their own default.
abstract class PlatformConfigRepository {
  Future<PlatformConfig?> get(String key);
}
