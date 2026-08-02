import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data.dart';
import '../../../data/models/seller_profile.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_sellers_controller.dart';

/// Pending seller applications awaiting the admin approval gate (AUTH-07).
class AdminSellersScreen extends StatelessWidget {
  const AdminSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Approval')),
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
    return AsyncView<List<SellerProfile>>(
      value: sellers,
      onRetry: () => ref.invalidate(adminSellersControllerProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No pending sellers',
              message: 'All seller applications have been reviewed.',
            )
          : ListView.separated(
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

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(adminSellersControllerProvider.notifier).approve(seller.userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${seller.farmName} approved')));
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(adminSellersControllerProvider.notifier).reject(seller.userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${seller.farmName} rejected')));
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
                      Text(seller.userId, style: theme.textTheme.bodySmall),
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
                  _IdentityImage(label: 'National ID', url: seller.nationalIdUrl),
                  const SizedBox(width: 12),
                  _IdentityImage(label: 'Selfie', url: seller.selfieUrl),
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
                    onPressed: () => _approve(context, ref),
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

/// A labelled identity document image with an `ImageNetwork` fallback when the
/// URL is empty (uploads are stubbed until the backend serves them).
class _IdentityImage extends StatelessWidget {
  final String label;
  final String? url;

  const _IdentityImage({required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = url != null && url!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasUrl
                ? ImageNetwork(url: url, width: 96, height: 72)
                : Container(
                    color: AppColors.backgroundElevated,
                    alignment: Alignment.center,
                    child: const Icon(Icons.badge_outlined, color: AppColors.tanDark),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark)),
      ],
    );
  }
}
