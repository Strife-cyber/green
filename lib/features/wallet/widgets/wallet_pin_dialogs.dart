import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../services/wallet_pin_service.dart';

/// Gates a sensitive wallet action (payment/withdrawal) behind the PIN
/// (PAY-10). Creates a PIN first when none is set. Returns `true` only when the
/// user verified a correct PIN; `false` on cancel or a wrong PIN — the caller
/// must then NOT proceed. Client-side enforcement for the demo; verification
/// moves server-side at the hand-off.
Future<bool> authorizeWalletAction(
  BuildContext context,
  WalletPinService pinService,
) async {
  if (await pinService.hasPin()) {
    if (!context.mounted) return false;
    final pin = await promptWalletPin(context);
    if (pin == null) return false;
    final ok = await pinService.verify(pin);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Try again.')),
      );
    }
    return ok;
  }
  if (!context.mounted) return false;
  final created = await promptSetWalletPin(context, pinService);
  return created;
}

/// Prompts for the current wallet PIN. Returns the entered PIN, or `null` if
/// the user cancelled.
Future<String?> promptWalletPin(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _PinEntryDialog(),
  );
}

/// Two-field "create your wallet PIN" dialog. Returns `true` once a PIN is
/// stored, `false` if cancelled.
Future<bool> promptSetWalletPin(BuildContext context, WalletPinService pinService) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _SetPinDialog(pinService: pinService),
  );
  return result ?? false;
}

const _pinInputDecoration = InputDecoration(
  labelText: '4-digit PIN',
  counterText: '',
  prefixIcon: Icon(Icons.pin_outlined),
  border: OutlineInputBorder(),
);

/// Entry dialog — 4-digit numeric PIN with a Verify action.
class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog();

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length == 4) Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your wallet PIN'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _pinInputDecoration,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

/// Create-a-PIN dialog — the two fields must match and be exactly 4 digits.
class _SetPinDialog extends StatefulWidget {
  final WalletPinService pinService;

  const _SetPinDialog({required this.pinService});

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.pinService.setPin(_pin.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _validatePin(String? value) {
    final v = value?.trim() ?? '';
    if (v.length != 4) return 'PIN must be 4 digits.';
    if (v != _confirm.text.trim()) return 'PINs do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a wallet PIN'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your PIN protects payments and withdrawals. It is stored as a salted hash — never in plaintext.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pin,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _pinInputDecoration,
              validator: (v) => (v ?? '').trim().length != 4 ? 'Enter 4 digits.' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _validatePin,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save PIN'),
        ),
      ],
    );
  }
}
