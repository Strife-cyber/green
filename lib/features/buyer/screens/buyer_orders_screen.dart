import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/order.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/buyer_order_list_controller.dart';

/// The buyer's order history (BUY-09): a tappable list with status + payment
/// badges, navigating to the order detail.
class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(buyerOrderListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('My Orders')),
      body: RefreshableAsyncView<List<Order>>(
        value: orders,
        onRefresh: () => ref.read(buyerOrderListControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(buyerOrderListControllerProvider),
        empty: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          message: 'Your orders will appear here once you check out.',
        ),
        builder: (items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(
            order: items[index],
            onTap: () async {
              await context.push(AppRoutes.orderDetail(items[index].id));
              if (context.mounted) {
                ref.invalidate(buyerOrderListControllerProvider);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                      order.sellerName ?? 'Order ${orderReference(order.id)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  AmountText(
                    order.totalAmount,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (order.placedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy · HH:mm').format(order.placedAt!),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusBadge.order(order.status),
                  StatusBadge.payment(order.paymentStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
