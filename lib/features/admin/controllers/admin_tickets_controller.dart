import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/support_ticket.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Support tickets raised through the enquiry desk (ADM-09). Scoped to the
/// signed-in user.
class AdminTicketsController extends AsyncNotifier<List<SupportTicket>> {
  @override
  Future<List<SupportTicket>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(adminRepositoryProvider).tickets();
  }

  /// Mark a ticket resolved, then re-fetch the list.
  Future<void> resolve(String id) async {
    await ref.read(adminRepositoryProvider).resolveTicket(id);
    ref.invalidateSelf();
  }

  /// Assign a ticket to the current admin, then re-fetch the list.
  Future<void> assign(String id) async {
    await ref.read(adminRepositoryProvider).assignTicket(id);
    ref.invalidateSelf();
  }
}

final adminTicketsControllerProvider =
    AsyncNotifierProvider<AdminTicketsController, List<SupportTicket>>(AdminTicketsController.new);
