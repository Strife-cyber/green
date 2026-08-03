import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/wallet.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';
import '../controllers/wallet_controller.dart';

/// The user's wallet balances (PAY-03).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Wallet')),
      body: RefreshableAsyncView<Wallet>(
        value: wallet,
        onRefresh: () => ref.read(walletControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(walletControllerProvider),
        builder: (data) {
          final theme = Theme.of(context);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.green,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total balance',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        data.total,
                        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _BalanceRow(label: 'Available', amount: data.balance, icon: Icons.account_balance_wallet_outlined),
                      const Divider(),
                      _BalanceRow(label: 'In escrow', amount: data.escrowBalance, icon: Icons.lock_outline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await context.push(AppRoutes.walletWithdraw);
                  ref.invalidate(walletControllerProvider);
                },
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Withdraw'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.walletTransactions),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Transaction history'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;

  const _BalanceRow({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tanDark),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          AmountText(amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
