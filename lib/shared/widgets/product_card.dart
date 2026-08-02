import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../theme/app_colors.dart';
import 'amount_text.dart';
import 'image_network.dart';

/// Compact product tile for grids (BUY-01).
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductCard({super.key, required this.product, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ImageNetwork(
                  url: product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != null)
                    Text(
                      product.categoryName!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  AmountText(product.pricePerKg, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (product.sellerName != null)
                    Text(
                      product.sellerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
