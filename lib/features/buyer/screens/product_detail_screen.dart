import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/product.dart';
import '../../../data/models/rating_review.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/quantity_stepper.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/wishlist_controller.dart';

/// Product detail (BUY-04): gallery image, category, name, price, stock,
/// quantity stepper, seller card with rating, add-to-cart and wishlist toggle.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  double _quantityKg = 0.5;

  @override
  void initState() {
    super.initState();
    ref.read(productDetailControllerProvider.notifier).load(widget.id);
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _quantityKg = 0.5;
      ref.read(productDetailControllerProvider.notifier).load(widget.id);
    }
  }

  void _addToCart(Product product) {
    ref.read(cartControllerProvider.notifier).add(product, _quantityKg);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistControllerProvider);
    final savedIds = wishlist.valueOrNull ?? const <String>{};
    final isSaved = savedIds.contains(widget.id);
    final product = ref.watch(productDetailControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove from wishlist' : 'Add to wishlist',
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? AppColors.orange : null,
            ),
            onPressed: () =>
                ref.read(wishlistControllerProvider.notifier).toggle(widget.id),
          ),
        ],
      ),
      body: AsyncView<Product>(
        value: product,
        onRetry: () =>
            ref.read(productDetailControllerProvider.notifier).load(widget.id),
        builder: (p) => _buildContent(context, p),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final soldOut = product.quantityKg <= 0;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: ImageNetwork(url: product.imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categoryName != null) ...[
                  Chip(
                    label: Text(product.categoryName!),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(product.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                AmountText(
                  product.pricePerKg,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (soldOut)
                  Text(
                    'Out of stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.orangeDark,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    'Available: ${_trimKg(product.quantityKg)} kg',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                if (product.description != null) ...[
                  const SizedBox(height: 16),
                  Text('Description', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(product.description!, style: theme.textTheme.bodyMedium),
                ],
                if (product.farmRegion != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: AppColors.tanDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${context.t.farmLocation}: ${product.farmRegion}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.tanDark),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (!soldOut)
                  Row(
                    children: [
                      Text('Quantity', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      QuantityStepper(
                        value: _quantityKg,
                        step: 0.5,
                        min: 0.5,
                        max: product.quantityKg,
                        onChanged: (value) => setState(() => _quantityKg = value),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _SellerCard(product: product),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: soldOut ? null : () => _addToCart(product),
                  icon: Icon(soldOut ? Icons.block : Icons.add_shopping_cart),
                  label: Text(soldOut ? 'Out of stock' : 'Add to cart'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

/// The tappable seller card (design 11): farm name · ★rating · N reviews ·
/// a Chat button opening the buyer↔seller thread, plus a report affordance.
class _SellerCard extends ConsumerWidget {
  final Product product;

  const _SellerCard({required this.product});

  /// Opens the direct buyer↔seller thread — falls back to a snackbar while
  /// the backend's seller-thread endpoint is still pending.
  Future<void> _chatWithSeller(BuildContext context, WidgetRef ref) async {
    ChatThread? thread;
    try {
      thread = await ref
          .read(chatRepositoryProvider)
          .threadForSeller(product.sellerId);
    } catch (_) {
      thread = null;
    }
    if (!context.mounted) return;
    if (thread != null) {
      context.push(AppRoutes.chat(thread.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.chatUnavailableSeller)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    final sellerId = product.sellerId;
    final sellerName = product.sellerName ?? t.roleSeller;
    final summary = ref.watch(sellerRatingProvider(sellerId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(name: sellerName, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sellerName, style: theme.textTheme.titleSmall),
                      summary.when(
                        data: (SellerRatingSummary s) => Text(
                          s.count == 0
                              ? t.noRatingsYet
                              : '${s.average.toStringAsFixed(1)} ★ · ${t.reviewsCount(count: s.count)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.tanDark),
                        ),
                        loading: () => Text(t.loadingRating,
                            style: theme.textTheme.bodySmall),
                        error: (_, _) => Text(t.roleSeller,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.reportSeller,
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  onPressed: () => showReportDialog(
                    context,
                    ref,
                    reportedId: sellerId,
                    targetType: ReportTargetType.profile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _chatWithSeller(context, ref),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(t.chatWithSeller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
