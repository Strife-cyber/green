import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/activity_log.dart';
import '../../../data/repositories/providers.dart';

/// The admin activity audit trail (ADM-15).
class AdminActivityController extends AsyncNotifier<List<ActivityLog>> {
  @override
  Future<List<ActivityLog>> build() => ref.watch(adminRepositoryProvider).activityLog();
}

final adminActivityControllerProvider =
    AsyncNotifierProvider<AdminActivityController, List<ActivityLog>>(AdminActivityController.new);
