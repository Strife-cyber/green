import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/admin_stats.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Loads the admin console aggregate metrics (ADM-01). Scoped to the
/// signed-in user.
class AdminStatsController extends AsyncNotifier<AdminStats> {
  @override
  Future<AdminStats> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const AdminStats(
        totalUsers: 0,
        activeSellers: 0,
        pendingSellers: 0,
        grossRevenue: 0,
        commissionEarned: 0,
        totalOrders: 0,
      );
    }
    return ref.watch(adminRepositoryProvider).stats();
  }

  /// Re-fetches the stats (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final adminStatsControllerProvider =
    AsyncNotifierProvider<AdminStatsController, AdminStats>(AdminStatsController.new);
