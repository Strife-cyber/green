import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n_ext.dart';

/// "Ask for the buyer's code" (design 24): the driver types the 6-digit code
/// the buyer received; the dialog returns it or null on cancel.
class BuyerCodeDialog extends StatefulWidget {
  const BuyerCodeDialog({super.key});

  @override
  State<BuyerCodeDialog> createState() => _BuyerCodeDialogState();
}

class _BuyerCodeDialogState extends State<BuyerCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length == 6) Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.askBuyerCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.askBuyerCodeBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 6),
            decoration: InputDecoration(
              hintText: '••••••',
              counterText: '',
              labelText: t.confirmationCode,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _controller.text.trim().length == 6 ? _submit : null,
          child: Text(t.confirmDeliveryAction),
        ),
      ],
    );
  }
}
