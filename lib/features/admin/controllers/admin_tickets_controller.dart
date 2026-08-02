import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/support_ticket.dart';
import '../../../data/repositories/providers.dart';

/// Support tickets raised through the enquiry desk (ADM-09).
class AdminTicketsController extends AsyncNotifier<List<SupportTicket>> {
  @override
  Future<List<SupportTicket>> build() => ref.watch(adminRepositoryProvider).tickets();

  /// Mark a ticket resolved, then re-fetch the list.
  Future<void> resolve(String id) async {
    await ref.read(adminRepositoryProvider).resolveTicket(id);
    ref.invalidateSelf();
  }
}

final adminTicketsControllerProvider =
    AsyncNotifierProvider<AdminTicketsController, List<SupportTicket>>(AdminTicketsController.new);
