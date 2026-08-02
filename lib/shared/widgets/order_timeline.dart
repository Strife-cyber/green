import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../theme/app_colors.dart';

/// Visual order lifecycle: pending → confirmed → shipped → delivered
/// (cancelled renders as a failure state). DEL-01.
class OrderTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderTimeline({super.key, required this.status});

  static const _steps = [
    ('Placed', Icons.receipt_outlined),
    ('Confirmed', Icons.check_circle_outline),
    ('Shipped', Icons.local_shipping_outlined),
    ('Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return _cancelled(context);
    }
    final activeIndex = switch (status) {
      OrderStatus.pending => 0,
      OrderStatus.confirmed => 1,
      OrderStatus.shipped => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => 0,
    };

    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: _Step(
              label: _steps[i].$1,
              icon: _steps[i].$2,
              reached: i <= activeIndex,
              isLast: i == _steps.length - 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _cancelled(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cancel_outlined, color: Color(0xFFB3261E)),
        const SizedBox(width: 8),
        Text('Order cancelled', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool reached;
  final bool isLast;

  const _Step({required this.label, required this.icon, required this.reached, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.green : AppColors.tan;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: reached ? AppColors.green.withValues(alpha: 0.6) : AppColors.tan.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: reached ? color : AppColors.tanDark,
                fontWeight: reached ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ],
    );
  }
}
