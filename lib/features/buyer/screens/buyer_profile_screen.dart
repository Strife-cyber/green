import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

/// Buyer profile (BUY-12): identity card, quick links to the account areas
/// and a log-out action. The router redirects automatically after logout.
class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final name = user?.fullName ?? 'Buyer';
    final email = user?.email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.navProfile),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  UserAvatar(name: name, radius: 36),
                  const SizedBox(height: 12),
                  Text(name, style: theme.textTheme.titleMedium),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileLink(
            icon: Icons.person_outline,
            title: context.t.editProfile,
            onTap: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(height: 4),
          _ProfileLink(
            icon: Icons.favorite_border,
            title: context.t.wishlist,
            onTap: () => context.push(AppRoutes.wishlist),
          ),
          const SizedBox(height: 4),
          _ProfileLink(
            icon: Icons.location_on_outlined,
            title: context.t.savedAddresses,
            onTap: () => context.push(AppRoutes.addresses),
          ),
          const SizedBox(height: 4),
          _ProfileLink(
            icon: Icons.receipt_long_outlined,
            title: context.t.myOrders,
            onTap: () => context.push(AppRoutes.buyerOrders),
          ),
          const SizedBox(height: 4),
          _ProfileLink(
            icon: Icons.notifications_outlined,
            title: context.t.notifications,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(height: 4),
          _ProfileLink(
            icon: Icons.support_agent_outlined,
            title: context.t.support,
            onTap: () => context.push(AppRoutes.support),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t.language, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  const LanguageSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(context.t.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB3261E),
              side: const BorderSide(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.green),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
