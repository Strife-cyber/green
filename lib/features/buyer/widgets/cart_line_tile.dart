import 'package:flutter/material.dart';

import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/quantity_stepper.dart';
import '../../../theme/app_colors.dart';
import '../controllers/cart_controller.dart';

/// A single cart line: product thumbnail, kg stepper, line total and remove
/// action (BUY-06).
class CartLineTile extends StatelessWidget {
  final CartLine line;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback? onRemove;

  const CartLineTile({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cap the stepper at live stock — 0 kg (sold out) disables both buttons.
    final maxKg = line.product.quantityKg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ImageNetwork(
                url: line.product.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  AmountText(
                    line.product.pricePerKg,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        value: line.quantityKg,
                        step: 0.5,
                        min: 0.5,
                        max: maxKg,
                        onChanged: onQuantityChanged,
                      ),
                      const Spacer(),
                      AmountText(
                        line.lineTotal,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline, color: AppColors.tanDark),
                        onPressed: onRemove,
                      ),
                    ],
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
