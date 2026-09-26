import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';

/// Order ids the seller has marked "prepared" this session. A soft, local
/// marking — the backend is not told (the seller only prepares; the driver
/// does the pickup). Prepared orders that are still CONFIRMED show in the
/// queue as "awaiting pickup".
final sellerPreparedProvider = StateProvider<Set<String>>(
  (ref) {
    // Session-scoped marks — reset when the account switches.
    ref.watch(currentUserIdProvider);
    return const <String>{};
  },
);
