import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../controllers/admin_wallets_controller.dart';

/// Every user wallet with balance + escrow, for admin oversight (ADM-04).
class AdminWalletsScreen extends StatelessWidget {
  const AdminWalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      body: const AdminWalletsBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Wallets" tab of the admin shell.
class AdminWalletsBody extends ConsumerWidget {
  const AdminWalletsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(adminWalletsControllerProvider);
    return AsyncView<List<Wallet>>(
      value: wallets,
      onRetry: () => ref.invalidate(adminWalletsControllerProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No wallets',
              message: 'No user wallets have been created yet.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _WalletCard(wallet: list[index]),
            ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: wallet.userId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.userId, style: theme.textTheme.titleMedium),
                      Text(wallet.id, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BalanceRow(label: 'Balance', amount: wallet.balance),
            const SizedBox(height: 4),
            _BalanceRow(label: 'In escrow', amount: wallet.escrowBalance),
            const Divider(height: 20),
            _BalanceRow(label: 'Total', amount: wallet.total, emphasized: true),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool emphasized;

  const _BalanceRow({required this.label, required this.amount, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        AmountText(amount, style: style),
      ],
    );
  }
}
