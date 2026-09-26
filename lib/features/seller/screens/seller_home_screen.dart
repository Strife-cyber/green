import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/nav_providers.dart';
import '../../../data/models/enums.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/screens/chat_threads_screen.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../controllers/seller_order_list_controller.dart';
import '../controllers/seller_product_list_controller.dart';
import '../controllers/seller_profile_controller.dart';
import 'seller_dashboard_screen.dart';
import 'seller_products_screen.dart';
import 'seller_profile_screen.dart';
import 'seller_queue_screen.dart';

/// Seller role home: a BraidsBook-style [AppShell] where the first tab is the
/// "what needs you now" queue, with catalog, analytics, chat and profile
/// behind tabs (AUTH-06). The seller only prepares orders — the driver picks
/// up — so there are no confirm/ship/assign actions anywhere on this flow.
class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> {
  bool _bannerShown = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // The pending/approved state lives on the auth session (set at signup and
    // by the demo logins), so it's read from there rather than the profile repo.
    final profile = ref.watch(authControllerProvider).valueOrNull?.sellerProfile;
    if (profile?.approvalStatus == SellerApprovalStatus.pending) {
      _showPendingBanner();
    }
    // Auto-refresh the active tab's data whenever the user switches tabs.
    ref.listen(sellerTabProvider, (previous, next) {
      if (previous == next) return;
      switch (next) {
        case 0: ref.invalidate(sellerOrderListControllerProvider); break;
        case 1: ref.invalidate(sellerProductListControllerProvider); break;
        case 2: ref.invalidate(sellerDashboardControllerProvider); break;
        case 3: break; // Chat is self-managing.
        case 4: ref.invalidate(sellerProfileControllerProvider); break;
      }
    });
    return AppShell(
      tabProvider: sellerTabProvider,
      persistKey: 'seller',
      tabs: [
        AppShellTab(label: t.navQueue, icon: Icons.inventory_2_outlined, page: const SellerQueueScreen()),
        AppShellTab(label: t.navProducts, icon: Icons.storefront_outlined, page: const SellerProductsScreen()),
        AppShellTab(label: t.navDashboard, icon: Icons.analytics_outlined, page: const SellerDashboardScreen()),
        AppShellTab(label: t.navChat, icon: Icons.chat_bubble_outline, page: const ChatThreadsScreen()),
        AppShellTab(label: t.navProfile, icon: Icons.person_outline, page: const SellerProfileScreen()),
      ],
    );
  }

  /// Pending-approval notice for unapproved sellers (AUTH-07).
  void _showPendingBanner() {
    if (_bannerShown) return;
    _bannerShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.orange.withValues(alpha: 0.18),
          leading: const Icon(Icons.hourglass_top, color: AppColors.orangeDark),
          content: Text(context.t.pendingApproval),
          actions: [
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: Text(context.t.ok),
            ),
          ],
        ),
      );
    });
  }
}
