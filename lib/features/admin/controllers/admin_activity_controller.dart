import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/activity_log.dart';
import '../../../data/repositories/providers.dart';

/// The admin activity audit trail (ADM-15).
class AdminActivityController extends AsyncNotifier<List<ActivityLog>> {
  @override
  Future<List<ActivityLog>> build() => ref.watch(adminRepositoryProvider).activityLog();

  /// Re-fetches the trail (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final adminActivityControllerProvider =
    AsyncNotifierProvider<AdminActivityController, List<ActivityLog>>(AdminActivityController.new);
