import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/seller_profile.dart';
import '../../../data/models/user.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/seller_profile_controller.dart';

/// Seller account profile with links and logout (AUTH-01/07).
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final profile = ref.watch(sellerProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.navProfile),
      ),
      body: AsyncView<SellerProfile>(
        value: profile,
        onRetry: () => ref.invalidate(sellerProfileControllerProvider),
        builder: (sellerProfile) => _ProfileContent(
          user: user,
          profile: sellerProfile,
          onLogout: () => _confirmLogout(context, ref),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be signed out of your seller account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User? user;
  final SellerProfile profile;
  final VoidCallback onLogout;

  const _ProfileContent({required this.user, required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user?.fullName ?? 'Seller';
    final email = user?.email;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                UserAvatar(name: displayName, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(profile.farmName, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
                      if (email != null)
                        Text(email, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
                    ],
                  ),
                ),
                StatusBadge(label: profile.approvalStatus.label, color: _approvalColor(profile.approvalStatus)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _LinkTile(icon: Icons.account_balance_wallet_outlined, title: context.t.wallet, onTap: () => context.push(AppRoutes.sellerWallet)),
              const Divider(height: 1),
              _LinkTile(icon: Icons.notifications_outlined, title: context.t.notifications, onTap: () => context.push(AppRoutes.notifications)),
              const Divider(height: 1),
              _LinkTile(icon: Icons.support_agent_outlined, title: context.t.support, onTap: () => context.push(AppRoutes.support)),
            ],
          ),
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
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: Text(context.t.logout),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3261E),
            side: const BorderSide(color: Color(0xFFB3261E)),
          ),
        ),
      ],
    );
  }

  Color _approvalColor(SellerApprovalStatus status) => switch (status) {
        SellerApprovalStatus.approved => AppColors.green,
        SellerApprovalStatus.pending => AppColors.orange,
        SellerApprovalStatus.rejected => const Color(0xFFB3261E),
      };
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greenDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.tanDark),
      onTap: onTap,
    );
  }
}
