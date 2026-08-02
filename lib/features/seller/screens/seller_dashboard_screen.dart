import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/seller_analytics.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/quick_actions.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../theme/app_colors.dart';
import '../controllers/seller_dashboard_controller.dart';

/// Seller analytics dashboard (SELL-03/04/05/07).
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(sellerDashboardControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.t.navDashboard)),
      body: AsyncView<SellerAnalytics>(
        value: analytics,
        onRetry: () => ref.invalidate(sellerDashboardControllerProvider),
        builder: (data) {
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Secondary actions live here — the bottom bar stays at 4.
              QuickActionsSection(
                actions: [
                  QuickAction(
                    icon: Icons.add_box_outlined,
                    label: context.t.qaAddProduct,
                    onTap: () => context.push('${AppRoutes.sellerProducts}/new'),
                  ),
                  QuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: context.t.qaOrders,
                    onTap: () => ref.read(sellerTabProvider.notifier).state = 2,
                  ),
                  QuickAction(
                    icon: Icons.account_balance_wallet_outlined,
                    label: context.t.qaWallet,
                    onTap: () => context.push(AppRoutes.sellerWallet),
                  ),
                  QuickAction(
                    icon: Icons.help_outline,
                    label: context.t.qaSupport,
                    onTap: () => context.push(AppRoutes.support),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Weekly revenue',
                      value: formatMoney(data.weeklyRevenue),
                      icon: Icons.payments_outlined,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Customers',
                      value: '${data.totalCustomers}',
                      icon: Icons.people_outline,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Rating',
                      value: '${data.averageRating.toStringAsFixed(1)} ★',
                      icon: Icons.star_outline,
                      color: AppColors.tanDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly sales', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      _SalesChart(points: data.monthlySales),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Best sellers', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (data.bestSellers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No sales yet.'),
                        )
                      else
                        for (final b in data.bestSellers) _BestSellerRow(item: b),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<SalesPoint> points;

  const _SalesChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No sales data yet.')));
    }
    final maxY = points.fold<double>(0, (max, p) => p.amount.toDouble() > max ? p.amount.toDouble() : max);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.25,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${points[index].day.day}',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].amount.toDouble())],
              isCurved: true,
              color: AppColors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.green.withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestSellerRow extends StatelessWidget {
  final BestSeller item;

  const _BestSellerRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item.quantitySold} kg sold', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
              ],
            ),
          ),
          AmountText(item.revenue, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
