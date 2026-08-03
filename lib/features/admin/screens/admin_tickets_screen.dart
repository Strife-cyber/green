import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/support_ticket.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_tickets_controller.dart';

/// Support tickets raised through the enquiry desk (ADM-09).
class AdminTicketsScreen extends StatelessWidget {
  const AdminTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Support Tickets')),
      body: const AdminTicketsBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Tickets" tab of the admin shell.
class AdminTicketsBody extends ConsumerWidget {
  const AdminTicketsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(adminTicketsControllerProvider);
    return AsyncView<List<SupportTicket>>(
      value: tickets,
      onRetry: () => ref.invalidate(adminTicketsControllerProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'No tickets',
              message: 'Support tickets will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TicketCard(ticket: list[index]),
            ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    await ref.read(adminTicketsControllerProvider.notifier).resolve(ticket.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket resolved')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resolved = ticket.status == TicketStatus.resolved;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ticket.subject, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: ticket.status.label,
                  color: switch (ticket.status) {
                    TicketStatus.open => AppColors.orange,
                    TicketStatus.assigned => const Color(0xFF4A7CBE),
                    TicketStatus.resolved => AppColors.green,
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ticket.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark),
            ),
            if (!resolved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _resolve(context, ref),
                  child: const Text('Resolve'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
