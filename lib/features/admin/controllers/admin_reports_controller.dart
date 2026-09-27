import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/report.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// User reports (profile/chat/order) awaiting admin review (ADM-07, D8).
/// Scoped to the signed-in user.
class AdminReportsController extends AsyncNotifier<List<Report>> {
  @override
  Future<List<Report>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(adminRepositoryProvider).reports();
  }

  /// Move a report to the given state, then re-fetch the list.
  /// `action: true` marks it actioned; `false` marks it reviewed.
  Future<void> applyAction(String id, {required bool action}) async {
    await ref.read(adminRepositoryProvider).actionReport(id, action: action);
    ref.invalidateSelf();
  }
}

final adminReportsControllerProvider =
    AsyncNotifierProvider<AdminReportsController, List<Report>>(AdminReportsController.new);
