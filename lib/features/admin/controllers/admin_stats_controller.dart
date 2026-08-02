import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/admin_stats.dart';
import '../../../data/repositories/providers.dart';

/// Loads the admin console aggregate metrics (ADM-01).
class AdminStatsController extends AsyncNotifier<AdminStats> {
  @override
  Future<AdminStats> build() => ref.watch(adminRepositoryProvider).stats();
}

final adminStatsControllerProvider =
    AsyncNotifierProvider<AdminStatsController, AdminStats>(AdminStatsController.new);
