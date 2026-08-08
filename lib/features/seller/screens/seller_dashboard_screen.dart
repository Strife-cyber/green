import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../data/models/seller_analytics.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/quick_actions.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/seller_dashboard_controller.dart';

/// Seller analytics dashboard (SELL-03/04/05/07).
///
/// Layout: greeting → quick actions → revenue hero → metric tiles → monthly
/// sales chart → best sellers. The hero anchors the page so the headline
/// number reads first; everything below it is supporting detail.
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(sellerDashboardControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final name = user?.firstName.trim();
    final greeting = (name == null || name.isEmpty)
        ? 'Welcome back'
        : 'Hi, $name';
    return Scaffold(
      // The greeting IS the header — replaces the old "Dashboard" title and the
      // language action; the avatar sits where the language icon used to be.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        centerTitle: false,
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              "Here's how your farm is doing today",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: UserAvatar(name: user?.fullName ?? '', radius: 20),
          ),
        ],
      ),
      body: RefreshableAsyncView<SellerAnalytics>(
        value: analytics,
        onRefresh: () =>
            ref.read(sellerDashboardControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(sellerDashboardControllerProvider),
        builder: (data) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // One line of icon-only actions — the bottom bar stays at 4.
              QuickActionsSection(
                actions: [
                  QuickAction(
                    icon: Icons.add_box_outlined,
                    label: context.t.qaAddProduct,
                    onTap: () =>
                        context.push('${AppRoutes.sellerProducts}/new'),
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
              _RevenueHero(weeklyRevenue: data.weeklyRevenue),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.people_outline,
                      accent: AppColors.orange,
                      value: '${data.totalCustomers}',
                      label: 'Customers',
                      caption: 'unique buyers',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.star_rounded,
                      accent: AppColors.greenDark,
                      value: data.averageRating.toStringAsFixed(1),
                      label: 'Rating',
                      caption: '${data.ratingCount} reviews',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ChartCard(points: data.monthlySales),
              const SizedBox(height: 16),
              _BestSellersCard(items: data.bestSellers),
            ],
          );
        },
      ),
    );
  }
}

/// The headline number — a full-width gradient card so weekly revenue reads
/// as the anchor of the page.
class _RevenueHero extends StatelessWidget {
  final int weeklyRevenue;

  const _RevenueHero({required this.weeklyRevenue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, AppColors.greenDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Soft decorative glows that peek out from behind the number.
            Positioned(top: -28, right: -28, child: _Glow(size: 120)),
            Positioned(bottom: -34, right: 44, child: _Glow(size: 76)),
            Positioned(
              right: 12,
              bottom: -20,
              child: Icon(
                Icons.eco,
                size: 92,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WEEKLY REVENUE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scale the big number down instead of overflowing on narrow screens.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AmountText(
                    weeklyRevenue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Earned over the last 7 days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;

  const _Glow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

/// A secondary metric tile: icon chip, big value, label and a caption.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String value;
  final String label;
  final String caption;

  const _MetricTile({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.tanDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<SalesPoint> points;

  const _ChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly sales',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Revenue per day this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.tanDark,
              ),
            ),
            const SizedBox(height: 16),
            _SalesChart(points: points),
          ],
        ),
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
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 28, color: AppColors.tan),
              const SizedBox(height: 8),
              Text(
                'No sales yet this month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.tanDark,
                ),
              ),
            ],
          ),
        ),
      );
    }
    var maxY = points.fold<double>(
      0,
      (m, p) => p.amount.toDouble() > m ? p.amount.toDouble() : m,
    );
    if (maxY <= 0) maxY = 1;
    final labelStep = points.length > 6 ? (points.length / 6).ceil() : 1;
    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.3,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.tan.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final isKey =
                      index == 0 ||
                      index == points.length - 1 ||
                      index % labelStep == 0;
                  if (!isKey) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${points[index].day.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.tanDark,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].amount.toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.orange, AppColors.green],
              ),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLast = index == points.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 4.5 : 2.5,
                    color: isLast ? AppColors.orange : Colors.white,
                    strokeWidth: isLast ? 2 : 1,
                    strokeColor: isLast
                        ? Colors.white
                        : AppColors.green.withValues(alpha: 0.7),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.green.withValues(alpha: 0.28),
                    AppColors.green.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestSellersCard extends StatelessWidget {
  final List<BestSeller> items;

  const _BestSellersCard({required this.items});

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
                Expanded(
                  child: Text(
                    'Best sellers',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Text(
                    '${items.length} top',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.tanDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No sales yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.tanDark,
                  ),
                ),
              )
            else
              for (final (index, b) in items.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 20,
                    color: AppColors.tan.withValues(alpha: 0.2),
                  ),
                _BestSellerRow(rank: index + 1, item: b),
              ],
          ],
        ),
      ),
    );
  }
}

class _BestSellerRow extends StatelessWidget {
  final int rank;
  final BestSeller item;

  const _BestSellerRow({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirst = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst
                  ? AppColors.orange
                  : AppColors.green.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isFirst ? Colors.white : AppColors.greenDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantitySold} kg sold',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.tanDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(
            item.revenue,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
