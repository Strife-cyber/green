import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

/// Formats an `int` FCFA amount as `2 500 FCFA` with the given style.
class AmountText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final TextAlign textAlign;

  const AmountText(this.amount, {super.key, this.style, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(formatMoney(amount), style: style, textAlign: textAlign);
  }
}
