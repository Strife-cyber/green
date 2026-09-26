import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';
import '../../order/order_status_text.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/seller_order_list_controller.dart';
import '../controllers/seller_queue_controller.dart';

/// The seller's "what needs you now" home (SELL-02 reworked): a queue of paid
/// orders to prepare, a count of prepared orders awaiting driver pickup, and
/// the ready-to-withdraw balance. The seller only prepares — the driver picks
/// up, so there are no confirm/ship/assign actions anywhere on this flow.
class SellerQueueScreen extends ConsumerWidget {
  const SellerQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final orders = ref.watch(sellerOrderListControllerProvider);
    final prepared = ref.watch(sellerPreparedProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.sellerQueueTitle)),
      body: RefreshableAsyncView<List<Order>>(
        value: orders,
        onRefresh: () =>
            ref.read(sellerOrderListControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(sellerOrderListControllerProvider),
        empty: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: t.sellerQueueTitle,
          message: t.noQueueHint,
        ),
        builder: (items) {
          final active = [
            for (final o in items)
              if (o.status == OrderStatus.confirmed) o,
          ];
          final toPrepare = [
            for (final o in active)
              if (!prepared.contains(o.id)) o,
          ];
          final awaiting = [
            for (final o in active)
              if (prepared.contains(o.id)) o,
          ];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _WalletStrip(),
              const SizedBox(height: 20),
              if (toPrepare.isNotEmpty) ...[
                Text(
                  t.ordersToPrepare(count: toPrepare.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final o in toPrepare) ...[
                  _QueueCard(order: o, prepared: false),
                  const SizedBox(height: 12),
                ],
              ],
              if (awaiting.isNotEmpty) ...[
                if (toPrepare.isNotEmpty) const SizedBox(height: 8),
                Text(
                  t.awaitingPickup(count: awaiting.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final o in awaiting) ...[
                  _QueueCard(order: o, prepared: true),
                  const SizedBox(height: 12),
                ],
              ],
              if (active.isEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    t.noQueueHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "X FCFA ready to withdraw" card → the seller wallet screen.
class _WalletStrip extends ConsumerWidget {
  const _WalletStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    final wallet = ref.watch(walletControllerProvider);
    return Card(
      color: AppColors.greenContainer.withValues(alpha: 0.55),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.sellerWallet),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.greenDark, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: wallet.when(
                  data: (w) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.readyToWithdraw(amount: formatMoney(w.balance)),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.wallet,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 34,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => Text(
                    t.wallet,
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.tanDark),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.tanDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// One queue entry: what to prepare (or what's prepared and waiting), where
/// it's headed, and a soft "Done" mark when it still needs preparing.
class _QueueCard extends ConsumerWidget {
  final Order order;
  final bool prepared;

  const _QueueCard({required this.order, required this.prepared});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.sellerOrderDetail(order.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      orderReference(order.id),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  AmountText(
                    order.totalAmount,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                orderStatusPhrase(context, order.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (order.deliveryAddressLabel != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.tanDark),
                    const SizedBox(width: 4),
                    Text(
                      order.deliveryAddressLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                t.itemCount(count: order.items.length),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: prepared
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.greenDark),
                          const SizedBox(width: 6),
                          Text(
                            t.awaitingPickupLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: () => ref
                            .read(sellerPreparedProvider.notifier)
                            .update((set) => {...set, order.id}),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(t.done),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.greenDark,
                          side: BorderSide(color: AppColors.green.withValues(alpha: 0.6)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
