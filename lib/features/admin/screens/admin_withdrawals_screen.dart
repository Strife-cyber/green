import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/withdrawal.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/admin_withdrawals_controller.dart';

/// Withdrawal requests awaiting admin processing (PAY-05).
class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Withdrawals')),
      body: const AdminWithdrawalsBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Withdrawals" tab of the admin shell.
class AdminWithdrawalsBody extends ConsumerWidget {
  const AdminWithdrawalsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawals = ref.watch(adminWithdrawalsControllerProvider);
    return RefreshableAsyncView<List<Withdrawal>>(
      value: withdrawals,
      onRefresh: () async => ref.invalidate(adminWithdrawalsControllerProvider),
      onRetry: () => ref.invalidate(adminWithdrawalsControllerProvider),
      empty: const EmptyState(
        icon: Icons.request_quote_outlined,
        title: 'No pending withdrawals',
        message: 'Withdrawal requests will appear here for processing.',
      ),
      builder: (list) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _WithdrawalCard(withdrawal: list[index]),
      ),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  final Withdrawal withdrawal;

  const _WithdrawalCard({required this.withdrawal});

  Future<void> _process(BuildContext context, WidgetRef ref, {required bool reject}) => _run(
        context,
        () => reject
            ? ref.read(adminWithdrawalsControllerProvider.notifier).reject(withdrawal.id)
            : ref.read(adminWithdrawalsControllerProvider.notifier).process(withdrawal.id),
        success: reject ? 'Withdrawal rejected' : 'Withdrawal processed',
      );

  /// Runs the mutation and surfaces the backend's message instead of an
  /// unhandled ApiException crashing the screen.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requested = withdrawal.requestedAt != null ? formatDateTime(withdrawal.requestedAt!) : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AmountText(withdrawal.amount, style: theme.textTheme.titleMedium),
                Text(withdrawal.channel.label, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Account', value: withdrawal.accountReference),
            _DetailRow(label: 'User', value: withdrawal.userId),
            if (requested.isNotEmpty) _DetailRow(label: 'Requested', value: requested),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _process(context, ref, reject: true),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _process(context, ref, reject: false),
                    child: const Text('Process'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
