import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/quantity_stepper.dart';
import '../../../theme/app_colors.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/wishlist_controller.dart';

/// Opens a product as a **draggable, scrollable bottom sheet** instead of a
/// full screen — faster to preview and add to the cart (BUY-04). Quantity is
/// controlled in kilograms (produce is sold per kg).
Future<void> showProductSheet(BuildContext context, WidgetRef ref, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) =>
          _ProductSheet(product: product, scrollController: scrollController),
    ),
  );
}

class _ProductSheet extends ConsumerStatefulWidget {
  final Product product;
  final ScrollController scrollController;

  const _ProductSheet({required this.product, required this.scrollController});

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  double _quantityKg = 1.0;
  bool _adding = false;

  Product get product => widget.product;

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() => _adding = true);

    // Brief loader so the tap visibly "does something", then close the sheet
    // and confirm on the root messenger (the sheet's context dies on pop).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = context.t.addedToCart(name: product.name, kg: '$_quantityKg');
    ref.read(cartControllerProvider.notifier).add(product, _quantityKg);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleWishlist() {
    ref.read(wishlistControllerProvider.notifier).toggle(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.tan.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [_header(), _details()],
                ),
                Positioned(left: 0, right: 0, bottom: 0, child: _BottomBar(
                  product: product,
                  adding: _adding,
                  onAddToCart: _addToCart,
                  onToggleWishlist: _toggleWishlist,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ImageNetwork(url: product.imageUrl, fit: BoxFit.cover),
        ),
        // Scrim so the close button + chip stay legible over the image.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        if (product.categoryName != null)
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.categoryName!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _details() {
    final theme = Theme.of(context);
    final t = context.t;
    final rating = ref.watch(sellerRatingProvider(product.sellerId));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          AmountText(
            product.pricePerKg,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: AppColors.greenDark),
              const SizedBox(width: 6),
              Text(product.sellerName ?? t.roleSeller, style: theme.textTheme.bodyMedium),
              if (rating.valueOrNull case final s?) ...[
                const SizedBox(width: 10),
                Text(
                  '★ ${s.average.toStringAsFixed(1)} · ${s.count}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                ),
              ],
            ],
          ),
          if (product.description != null) ...[
            const SizedBox(height: 16),
            Text(product.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          if (product.quantityKg <= 0)
            _outOfStock(theme)
          else ...[
            Row(
              children: [
                Text(t.quantity, style: theme.textTheme.titleSmall),
                const Spacer(),
                QuantityStepper(
                  value: _quantityKg,
                  step: 0.5,
                  min: 0.5,
                  max: product.quantityKg,
                  onChanged: (v) => setState(() => _quantityKg = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_trimKg(product.quantityKg)} kg available',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _outOfStock(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tan.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block, size: 16, color: AppColors.orangeDark),
          const SizedBox(width: 6),
          Text(
            'Out of stock',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.orangeDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

class _BottomBar extends ConsumerWidget {
  final Product product;
  final bool adding;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;

  const _BottomBar({
    required this.product,
    required this.adding,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final theme = Theme.of(context);
    final savedIds = ref.watch(wishlistControllerProvider).valueOrNull ?? const <String>{};
    final isSaved = savedIds.contains(product.id);
    final soldOut = product.quantityKg <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onToggleWishlist,
              tooltip: isSaved ? 'Remove from wishlist' : 'Add to wishlist',
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? const Color(0xFFB3261E) : AppColors.tanDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: (adding || soldOut) ? null : onAddToCart,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                icon: adding
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(soldOut ? Icons.block : Icons.add_shopping_cart),
                label: adding
                    ? const SizedBox.shrink()
                    : Text(soldOut ? 'Out of stock' : t.addToCart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
