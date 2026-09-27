import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';
import '../../order/order_status_text.dart';
import '../controllers/buyer_order_list_controller.dart';

/// The buyer's order history (BUY-09): one card per order with a plain-language
/// status line and the amount, navigating to the order detail.
class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(buyerOrderListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.myOrders)),
      body: RefreshableAsyncView<List<Order>>(
        value: orders,
        onRefresh: () => ref.read(buyerOrderListControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(buyerOrderListControllerProvider),
        empty: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: context.t.noOrdersYet,
          message: context.t.noOrdersYetHint,
        ),
        builder: (items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = items[index];
            return _OrderCard(
              order: order,
              onTap: () async {
                await context.push(AppRoutes.orderDetail(order.id));
                if (context.mounted) {
                  ref.invalidate(buyerOrderListControllerProvider);
                }
              },
              // An order a buyer left unpaid mid-checkout can be resumed here.
              onPayNow: () => context.push(AppRoutes.payment(order.id)),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onPayNow;

  const _OrderCard({required this.order, required this.onTap, this.onPayNow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    // Same gate as the order detail: a cancelled order stays UNPAID but must
    // never offer Pay now.
    final canPay = order.paymentStatus == PaymentStatus.unpaid &&
        order.status != OrderStatus.cancelled;
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
              const SizedBox(height: 6),
              Text(
                orderStatusPhrase(context, order.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (order.placedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy · HH:mm').format(order.placedAt!),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                t.itemCount(count: order.items.length),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              ),
              if (canPay && onPayNow != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onPayNow,
                    icon: const Icon(Icons.payment, size: 18),
                    label: Text(t.payNow),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.orangeDark,
                      side: const BorderSide(color: AppColors.orange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
