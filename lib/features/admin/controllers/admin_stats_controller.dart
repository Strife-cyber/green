import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/admin_stats.dart';
import '../../../data/repositories/providers.dart';

/// Loads the admin console aggregate metrics (ADM-01).
class AdminStatsController extends AsyncNotifier<AdminStats> {
  @override
  Future<AdminStats> build() => ref.watch(adminRepositoryProvider).stats();

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
