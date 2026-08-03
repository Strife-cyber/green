import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/seller_order_list_controller.dart';

/// Orders placed with the seller (SELL-02).
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(sellerOrderListControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Orders')),
      body: RefreshableAsyncView<List<Order>>(
        value: orders,
        onRefresh: () => ref.read(sellerOrderListControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(sellerOrderListControllerProvider),
        empty: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          message: 'New orders will appear here.',
        ),
        builder: (items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(
            order: items[index],
            onTap: () async {
              await context.push(AppRoutes.sellerOrderDetail(items[index].id));
              ref.invalidate(sellerOrderListControllerProvider);
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderReference(order.id), style: theme.textTheme.titleSmall),
                    if (order.placedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatDateTime(order.placedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.order(order.status),
                  const SizedBox(height: 6),
                  AmountText(order.totalAmount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
