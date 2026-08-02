import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../theme/app_colors.dart';

/// Colour-coded status pill for orders and payments.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.order(OrderStatus status) => StatusBadge(
        label: status.label,
        color: switch (status) {
          OrderStatus.pending => AppColors.tanDark,
          OrderStatus.confirmed => const Color(0xFF4A7CBE),
          OrderStatus.shipped => AppColors.orange,
          OrderStatus.delivered => AppColors.green,
          OrderStatus.cancelled => const Color(0xFFB3261E),
        },
      );

  factory StatusBadge.payment(PaymentStatus status) => StatusBadge(
        label: status.label,
        color: switch (status) {
          PaymentStatus.unpaid => AppColors.tanDark,
          PaymentStatus.paid || PaymentStatus.escrowHeld => AppColors.orange,
          PaymentStatus.settled => AppColors.green,
          PaymentStatus.refunded => const Color(0xFF4A7CBE),
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
