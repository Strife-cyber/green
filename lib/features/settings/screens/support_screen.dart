import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/support_ticket.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/support_controller.dart';

/// Customer enquiry desk: your tickets plus a "new ticket" form (ADM-10).
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  void _openNewTicket() {
    _formKey.currentState?.reset();
    _subject.clear();
    _description.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New ticket', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                FormTextField(
                  controller: _subject,
                  label: 'Subject',
                  textInputAction: TextInputAction.next,
                  validator: (value) => validateRequired(value, 'Subject'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => validateRequired(value, 'Description'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Submit ticket'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(supportControllerProvider.notifier).create(
            subject: _subject.text.trim(),
            description: _description.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not submit the ticket. Try again.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Support')),
      body: AsyncView<List<SupportTicket>>(
        value: tickets,
        onRetry: () => ref.invalidate(supportControllerProvider),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'No tickets yet',
                message: 'Questions or issues? Open a ticket and we will get back to you.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _TicketCard(ticket: list[index]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = ticket.createdAt != null ? formatDateTime(ticket.createdAt!) : '';
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
            if (created.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(created, style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}
