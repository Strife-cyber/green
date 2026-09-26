import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/seller_profile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_sellers_controller.dart';

/// Pending seller applications awaiting the admin approval gate (AUTH-07).
class AdminSellersScreen extends StatelessWidget {
  const AdminSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Seller Approval')),
      body: const AdminSellersBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Sellers" tab of the admin shell.
class AdminSellersBody extends ConsumerWidget {
  const AdminSellersBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellers = ref.watch(adminSellersControllerProvider);
    return RefreshableAsyncView<List<SellerProfile>>(
      value: sellers,
      onRefresh: () async => ref.invalidate(adminSellersControllerProvider),
      onRetry: () => ref.invalidate(adminSellersControllerProvider),
      empty: const EmptyState(
        icon: Icons.storefront_outlined,
        title: 'No pending sellers',
        message: 'All seller applications have been reviewed.',
      ),
      builder: (list) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _SellerCard(seller: list[index]),
      ),
    );
  }
}

class _SellerCard extends ConsumerWidget {
  final SellerProfile seller;

  const _SellerCard({required this.seller});

  /// The backend blocks approval until both identity documents are uploaded
  /// (AUTH-09 / seller-profiles.service.ts) — gate the button to match.
  bool get _readyToApprove => seller.nationalIdUrl != null && seller.selfieUrl != null;

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Approve ${seller.farmName}?',
      message: 'This activates the seller account. The seller will be able to list and sell products.',
      confirmLabel: 'Approve',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await _run(
      context,
      () => ref.read(adminSellersControllerProvider.notifier).approve(seller.userId),
      success: '${seller.farmName} approved',
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Reject ${seller.farmName}?',
      message: 'The seller will be notified and must re-upload identity documents to reapply.',
      confirmLabel: 'Reject',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await _run(
      context,
      () => ref.read(adminSellersControllerProvider.notifier).reject(seller.userId),
      success: '${seller.farmName} rejected',
    );
  }

  /// Confirmation dialog — approve/reject flips a seller's account state, so a
  /// tap shouldn't fire it without explicit consent (AUTH-07).
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Runs an admin mutation and reports the outcome, surfacing the backend's
  /// own message (e.g. missing identity documents) instead of an unhandled
  /// ApiException crashing the screen.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong.')),
        );
      }
    }
  }

  String? get _categoryName {
    for (final category in MockData.categories) {
      if (category.id == seller.mainCategoryId) return category.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryName = _categoryName;
    // Documents are decrypt-on-read endpoints that require the admin's JWT.
    final accessToken =
        ref.read(authControllerProvider).valueOrNull?.session?.accessToken ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: seller.farmName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seller.farmName, style: theme.textTheme.titleMedium),
                      //Text(seller.userId, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (categoryName != null)
              Text(
                categoryName,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.greenDark, fontWeight: FontWeight.w600),
              ),
            if (seller.farmDescription != null) ...[
              const SizedBox(height: 8),
              Text(seller.farmDescription!, style: theme.textTheme.bodyMedium),
            ],
            if (seller.nationalIdUrl != null ||
                seller.selfieUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _IdentityImage(
                    label: 'National ID',
                    userId: seller.userId,
                    kind: 'nationalId',
                    token: accessToken,
                    hasDoc: seller.nationalIdUrl != null,
                  ),
                  const SizedBox(width: 12),
                  _IdentityImage(
                    label: 'Selfie',
                    userId: seller.userId,
                    kind: 'selfie',
                    token: accessToken,
                    hasDoc: seller.selfieUrl != null,
                  ),
                ],
              ),
            ],
            if (!_readyToApprove) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.orangeDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Waiting on identity documents (National ID + selfie) from the seller before approval.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeDark),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(context, ref),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _readyToApprove ? () => _approve(context, ref) : null,
                    child: const Text('Approve'),
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

/// A labelled identity document image. Documents are encrypted at rest and
/// served only through the authenticated decrypt-on-read endpoint
/// (`GET /admin/seller-profiles/:userId/documents/:kind`), so the stored
/// `nationalIdUrl`/`selfieUrl` metadata is used only to decide whether the
/// document exists — the image itself needs the admin's Bearer token.
class _IdentityImage extends StatelessWidget {
  final String label;
  final String userId;
  final String kind;
  final String token;
  final bool hasDoc;

  const _IdentityImage({
    required this.label,
    required this.userId,
    required this.kind,
    required this.token,
    required this.hasDoc,
  });

  String get _url => (hasDoc && token.isNotEmpty)
      ? Endpoints.adminSellerDocuments
          .replaceAll('{userId}', Uri.encodeComponent(userId))
          .replaceAll('{kind}', kind)
      : '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _url.isEmpty ? null : () => _open(context),
          child: SizedBox(
            width: 96,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _url.isEmpty
                      ? Container(
                          color: AppColors.backgroundElevated,
                          alignment: Alignment.center,
                          child: const Icon(Icons.badge_outlined, color: AppColors.tanDark),
                        )
                      : ImageNetwork(
                          url: _url,
                          width: 96,
                          height: 72,
                          headers: {'Authorization': 'Bearer $token'},
                        ),
                ),
                if (_url.isNotEmpty)
                  const Positioned(
                    right: 4,
                    bottom: 4,
                    child: Icon(
                      Icons.zoom_in,
                      size: 16,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark)),
      ],
    );
  }

  /// Opens the document fullscreen (pinch-zoomable) for review — served by the
  /// same authenticated endpoint as the thumbnail.
  void _open(BuildContext context) {
    if (_url.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: SizedBox.expand(
                  child: ImageNetwork(
                    url: _url,
                    headers: {'Authorization': 'Bearer $token'},
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
