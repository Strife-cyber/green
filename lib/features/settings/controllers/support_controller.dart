import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/support_ticket.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/support_repository.dart';

/// The customer's support tickets plus the "new ticket" action (ADM-10).
class SupportController extends AsyncNotifier<List<SupportTicket>> {
  @override
  Future<List<SupportTicket>> build() => ref.watch(supportRepositoryProvider).myTickets();

  /// Create a new ticket, then refresh the list so it appears immediately.
  Future<void> create({required String subject, required String description}) async {
    await ref
        .read(supportRepositoryProvider)
        .create(CreateTicketInput(subject: subject, description: description));
    ref.invalidateSelf();
  }
}

final supportControllerProvider =
    AsyncNotifierProvider<SupportController, List<SupportTicket>>(SupportController.new);
