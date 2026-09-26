import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/seller_profile.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/photo_picker.dart';
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
        if (profile.approvalStatus == SellerApprovalStatus.rejected) ...[
          const _RejectedDocumentsCard(),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              _LinkTile(icon: Icons.person_outline, title: context.t.editProfile, onTap: () => context.push(AppRoutes.profile)),
              const Divider(height: 1),
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

/// Shown when a seller application was rejected (AUTH-07): lets the seller
/// re-upload identity documents so the profile can be reviewed again. Once
/// both documents are on file, the upload calls `POST /seller-profiles/me/
/// resubmit` to put the profile back in the PENDING queue.
class _RejectedDocumentsCard extends ConsumerStatefulWidget {
  const _RejectedDocumentsCard();

  @override
  ConsumerState<_RejectedDocumentsCard> createState() =>
      _RejectedDocumentsCardState();
}

class _RejectedDocumentsCardState extends ConsumerState<_RejectedDocumentsCard> {
  bool _uploading = false;

  Future<void> _upload(String field) async {
    if (_uploading) return;
    final path = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload identity document',
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 16),
            PhotoPicker(
              size: 140,
              onPicked: (p) => Navigator.of(sheetContext).pop(p),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    final repo = ref.read(sellerProfileRepositoryProvider);
    try {
      if (field == 'nationalId') {
        await repo.uploadNationalId(path);
      } else {
        await repo.uploadSelfie(path);
      }
      await ref.read(sellerProfileControllerProvider.notifier).refresh();
      // Best-effort re-submission: once BOTH documents are on file the profile
      // flips back to PENDING and the rejected banner clears. A 400 while the
      // second document is still missing just means "not yet" — the upload
      // itself succeeded and stays acknowledged.
      try {
        await repo.resubmit();
        await ref.read(sellerProfileControllerProvider.notifier).refresh();
      } catch (_) {
        // One document still missing — wait for the other.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.documentsUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.uploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.backgroundElevated,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.sellerRejectedTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: const Color(0xFFB3261E)),
            ),
            const SizedBox(height: 4),
            Text(
              context.t.sellerRejectedBody,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _upload('nationalId'),
                    icon: const Icon(Icons.badge_outlined),
                    label: Text(context.t.reUploadNationalId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _upload('selfie'),
                    icon: const Icon(Icons.face_outlined),
                    label: Text(context.t.reUploadSelfie),
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
