import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/admin_stats.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/language_action.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/quick_actions.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_sellers_controller.dart';
import '../controllers/admin_stats_controller.dart';
import '../controllers/admin_withdrawals_controller.dart';
import 'admin_sellers_screen.dart';
import 'admin_withdrawals_screen.dart';

/// Admin console home — a BraidsBook-style [AppShell] with a **4-tab** bottom
/// nav (Overview, Sellers, Withdrawals, Profile). Every other module (wallet,
/// deliveries, tickets, reports, activity, new driver) lives in the Overview
/// **quick actions** — never more than 4 items in one bottom bar.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    // Auto-refresh the active tab's data whenever the user switches tabs.
    ref.listen(adminTabProvider, (previous, next) {
      if (previous == next) return;
      switch (next) {
        case 0: ref.invalidate(adminStatsControllerProvider); break;
        case 1: ref.invalidate(adminSellersControllerProvider); break;
        case 2: ref.invalidate(adminWithdrawalsControllerProvider); break;
        // 3 = Profile — nothing to refetch.
      }
    });
    return AppShell(
      tabProvider: adminTabProvider,
      persistKey: 'admin',
      tabs: [
        AppShellTab(label: t.navOverview, icon: Icons.dashboard_outlined, page: const _OverviewTab()),
        AppShellTab(label: t.navSellers, icon: Icons.storefront_outlined, page: _AdminTab(title: t.navSellers, child: const AdminSellersBody())),
        AppShellTab(label: t.navWithdrawals, icon: Icons.request_quote_outlined, page: _AdminTab(title: t.navWithdrawals, child: const AdminWithdrawalsBody())),
        AppShellTab(label: t.navProfile, icon: Icons.person_outline, page: const _ProfileTab()),
      ],
    );
  }
}

/// Wraps a content-only admin module body in its own header (each tab page is
/// a self-contained Scaffold — no double AppBar).
class _AdminTab extends StatelessWidget {
  final String title;
  final Widget child;

  const _AdminTab({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(title)), body: child);
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final name = user?.fullName ?? t.roleAdmin;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(child: UserAvatar(name: name, radius: 40)),
          const SizedBox(height: 16),
          Center(
            child: Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(user?.email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(t.roleAdmin, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.language, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  const LanguageSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text(t.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final stats = ref.watch(adminStatsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.adminConsole),
        actions: const [LanguageAction()],
      ),
      body: RefreshableAsyncView<AdminStats>(
        value: stats,
        onRefresh: () => ref.read(adminStatsControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(adminStatsControllerProvider),
        builder: (s) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Every secondary module lives here — the bottom bar stays at 4.
            QuickActionsSection(
              actions: [
                QuickAction(
                  icon: Icons.local_shipping_outlined,
                  label: t.navDeliveries,
                  onTap: () => context.push(AppRoutes.adminDeliveries),
                ),
                QuickAction(
                  icon: Icons.support_agent_outlined,
                  label: t.navTickets,
                  onTap: () => context.push(AppRoutes.adminTickets),
                ),
                QuickAction(
                  icon: Icons.flag_outlined,
                  label: t.navReports,
                  onTap: () => context.push(AppRoutes.adminReports),
                ),
                QuickAction(
                  icon: Icons.person_add_alt,
                  label: t.newDriver,
                  onTap: () => context.push(AppRoutes.adminCreateDriver),
                ),
                QuickAction(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  onTap: () => context.push(AppRoutes.adminCategories),
                ),
                QuickAction(
                  icon: Icons.emoji_transportation_outlined,
                  label: 'Drivers',
                  onTap: () => context.push(AppRoutes.adminDrivers),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                StatCard(label: t.statTotalUsers, value: '${s.totalUsers}', icon: Icons.people_outline),
                StatCard(label: t.statActiveSellers, value: '${s.activeSellers}', icon: Icons.storefront_outlined),
                StatCard(
                  label: t.statPendingSellers,
                  value: '${s.pendingSellers}',
                  icon: Icons.hourglass_top,
                  color: AppColors.orange,
                ),
                StatCard(
                  label: t.statGrossRevenue,
                  value: formatMoney(s.grossRevenue),
                  icon: Icons.trending_up,
                  color: AppColors.orange,
                ),
                StatCard(label: t.statCommission, value: formatMoney(s.commissionEarned), icon: Icons.payments_outlined),
                StatCard(label: t.statTotalOrders, value: '${s.totalOrders}', icon: Icons.receipt_long_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
