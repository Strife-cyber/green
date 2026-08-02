import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// - / + stepper for kg quantities (BUY-04/06).
class QuantityStepper extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    this.step = 0.5,
    this.min = 0.5,
    this.max = 1000,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.tan),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${_trim(value)} kg',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _Button(
            icon: Icons.add,
            onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          ),
        ],
      ),
    );
  }

  String _trim(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

class _Button extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _Button({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.tan : AppColors.greenDark),
      ),
    );
  }
}
