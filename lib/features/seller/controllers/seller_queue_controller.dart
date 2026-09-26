import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Order ids the seller has marked "prepared" this session. A soft, local
/// marking — the backend is not told (the seller only prepares; the driver
/// does the pickup). Prepared orders that are still CONFIRMED show in the
/// queue as "awaiting pickup".
final sellerPreparedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);
