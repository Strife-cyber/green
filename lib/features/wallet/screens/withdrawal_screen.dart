import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../theme/app_colors.dart';
import '../controllers/withdrawal_controller.dart';
import '../controllers/wallet_controller.dart';
import '../services/wallet_pin_service.dart';
import '../widgets/wallet_pin_dialogs.dart';

/// Request a wallet withdrawal (PAY-05).
class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _account = TextEditingController();
  WithdrawalChannel _channel = WithdrawalChannel.mtnMomo;

  @override
  void dispose() {
    _amount.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final balance = ref.read(walletControllerProvider).valueOrNull?.balance ?? 0;
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds your available balance.')),
      );
      return;
    }
    // Wallet-PIN gate before the request leaves the device (PAY-10). Client-side
    // enforcement for the demo; verification moves server-side at hand-off.
    final authorized = await authorizeWalletAction(context, ref.read(walletPinServiceProvider));
    if (!authorized || !mounted) return;
    await ref.read(withdrawalControllerProvider.notifier).request(
          amount: amount,
          channel: _channel,
          accountReference: _account.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(withdrawalControllerProvider);
    final submitting = state is WithdrawalSubmitting;

    ref.listen<WithdrawalState>(withdrawalControllerProvider, (_, next) {
      if (next is WithdrawalDone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted.')),
        );
        context.pop();
      } else if (next is WithdrawalError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Minimum withdrawal is 2 000 FCFA.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _amount,
              label: 'Amount (FCFA)',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.currency_exchange),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WithdrawalChannel>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Channel'),
              items: [
                for (final c in WithdrawalChannel.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _channel = v ?? _channel),
            ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _account,
              label: 'Account reference (phone)',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: validatePhone,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required.';
    final amount = int.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter a valid amount.';
    if (amount < 2000) return 'Minimum withdrawal is 2 000 FCFA.';
    return null;
  }
}
