import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/product.dart';
import '../../../data/models/rating_review.dart';
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Quantity', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    QuantityStepper(
                      value: _quantityKg,
                      step: 0.5,
                      min: 0.5,
                      max: product.quantityKg > 0 ? product.quantityKg : 1000,
                      onChanged: (value) => setState(() => _quantityKg = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SellerCard(
                  sellerId: product.sellerId,
                  sellerName: product.sellerName,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _addToCart(product),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to cart'),
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

/// Compact seller card with the aggregated seller rating (BUY-11).
class _SellerCard extends ConsumerWidget {
  final String sellerId;
  final String? sellerName;

  const _SellerCard({required this.sellerId, this.sellerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(sellerRatingProvider(sellerId));
    return Card(
      child: ListTile(
        leading: UserAvatar(name: sellerName ?? 'Seller', radius: 24),
        title: Text(sellerName ?? 'Seller', style: theme.textTheme.titleSmall),
        subtitle: summary.when(
          data: (SellerRatingSummary s) => Text(
            s.count == 0
                ? 'No ratings yet'
                : '${s.average.toStringAsFixed(1)} ★ · ${s.count} ratings',
          ),
          loading: () => const Text('Loading rating…'),
          error: (_, _) => const Text('Seller'),
        ),
        trailing: IconButton(
          tooltip: 'Report this seller',
          icon: const Icon(Icons.flag_outlined, size: 20),
          onPressed: () => showReportDialog(
            context,
            ref,
            reportedId: sellerId,
            targetType: ReportTargetType.profile,
          ),
        ),
      ),
    );
  }
}
