import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';
import '../controllers/seller_order_list_controller.dart';

/// Orders placed with the seller (SELL-02, design 34) — New / Shipping /
/// Done tabs so PENDING orders are browsable without a deep link.
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(sellerOrderListControllerProvider);
    final t = context.t;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context) ? const BackButton() : null,
          title: Text(t.navOrders),
          bottom: TabBar(
            tabs: [
              Tab(text: t.ordersTabNew),
              Tab(text: t.ordersTabShipping),
              Tab(text: t.ordersTabDone),
            ],
          ),
        ),
        body: RefreshableAsyncView<List<Order>>(
          value: orders,
          onRefresh: () =>
              ref.read(sellerOrderListControllerProvider.notifier).refresh(),
          onRetry: () => ref.invalidate(sellerOrderListControllerProvider),
          empty: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: t.noOrdersInTab,
            message: t.noOrdersYetHint,
          ),
          builder: (items) => TabBarView(
            children: [
              _OrderList(
                orders: items.where((o) => o.status == OrderStatus.pending).toList(),
                onChanged: () => ref.invalidate(sellerOrderListControllerProvider),
              ),
              _OrderList(
                orders: items
                    .where((o) =>
                        o.status == OrderStatus.confirmed ||
                        o.status == OrderStatus.shipped)
                    .toList(),
                onChanged: () => ref.invalidate(sellerOrderListControllerProvider),
              ),
              _OrderList(
                orders: items
                    .where((o) =>
                        o.status == OrderStatus.delivered ||
                        o.status == OrderStatus.cancelled)
                    .toList(),
                onChanged: () => ref.invalidate(sellerOrderListControllerProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final VoidCallback onChanged;

  const _OrderList({required this.orders, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.t.noOrdersInTab,
            message: context.t.noOrdersYetHint,
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(
        order: orders[index],
        onTap: () async {
          await context.push(AppRoutes.sellerOrderDetail(orders[index].id));
          onChanged();
        },
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
