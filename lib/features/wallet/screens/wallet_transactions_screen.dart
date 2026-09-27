import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/file_download.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/ledger_controller.dart';

/// The wallet ledger (design 22): filter chips per movement kind plus a
/// statement export (`GET /transactions/me/export` CSV).
class WalletTransactionsScreen extends ConsumerStatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  ConsumerState<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

/// The chips are All · Payments · Escrow · Commission · Withdrawals. Escrow
/// covers BOTH escrow_hold and escrow_release, which the single-value `?type=`
/// query can't express — for that chip the screen fetches the full ledger and
/// filters client-side; the others go to the API directly.
enum _Kind { all, payments, escrow, commission, withdrawals }

class _WalletTransactionsScreenState
    extends ConsumerState<WalletTransactionsScreen> {
  _Kind _kind = _Kind.all;

  TransactionType? get _apiFilter => switch (_kind) {
        _Kind.payments => TransactionType.paymentIn,
        _Kind.commission => TransactionType.commission,
        _Kind.withdrawals => TransactionType.withdrawal,
        _Kind.all || _Kind.escrow => null,
      };

  /// Downloads the CSV statement produced by `GET /transactions/me/export`.
  Future<void> _export() async {
    try {
      final csv = await ref.read(walletRepositoryProvider).exportTransactions();
      if (!mounted) return;
      await downloadFile(
        bytes: Uint8List.fromList(csv.bytes),
        filename: csv.filename,
        mimeType: 'text/csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.statementExported)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.downloadFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerControllerProvider(_apiFilter));
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.transactions),
        actions: [
          IconButton(
            tooltip: t.exportStatement,
            icon: const Icon(Icons.download_outlined),
            onPressed: _export,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(t.all, _Kind.all),
                _chip(t.filterPayments, _Kind.payments),
                _chip(t.filterEscrow, _Kind.escrow),
                _chip(t.filterCommission, _Kind.commission),
                _chip(t.filterWithdrawals, _Kind.withdrawals),
              ],
            ),
          ),
          Expanded(
            child: RefreshableAsyncView<List<WalletTransaction>>(
              value: ledger,
              onRefresh: () => ref
                  .read(ledgerControllerProvider(_apiFilter).notifier)
                  .refresh(),
              onRetry: () =>
                  ref.invalidate(ledgerControllerProvider(_apiFilter)),
              empty: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: t.noTransactionsYet,
                message: t.walletActivityAppearsHere,
              ),
              builder: (items) {
                final visible = _kind == _Kind.escrow
                    ? items
                        .where((tx) =>
                            tx.type == TransactionType.escrowHold ||
                            tx.type == TransactionType.escrowRelease)
                        .toList()
                    : items;
                if (visible.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: t.noTransactionsYet,
                        message: t.walletActivityAppearsHere,
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _TransactionTile(tx: visible[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Kind kind) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _kind == kind,
        onSelected: (_) => setState(() => _kind = kind),
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
          Icon(
            isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatDateTime(tx.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.tanDark),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '−'} ${formatAmount(tx.amount.abs())} FCFA',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              Text(
                'Balance: ${formatMoney(tx.balanceAfter)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.tanDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
