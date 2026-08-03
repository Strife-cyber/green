import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/ledger_controller.dart';

/// The wallet ledger — every credit and debit (PAY-07).
class WalletTransactionsScreen extends ConsumerWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Transactions')),
      body: RefreshableAsyncView<List<WalletTransaction>>(
        value: ledger,
        onRefresh: () => ref.read(ledgerControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(ledgerControllerProvider),
        empty: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet',
          message: 'Your wallet activity will appear here.',
        ),
        builder: (items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _TransactionTile(tx: items[index]),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = tx.type.isCredit;
    final color = isCredit ? AppColors.green : AppColors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.type.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(formatDateTime(tx.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '−'} ${formatAmount(tx.amount.abs())} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              Text('Balance: ${formatMoney(tx.balanceAfter)}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
            ],
          ),
        ],
      ),
    );
  }
}
