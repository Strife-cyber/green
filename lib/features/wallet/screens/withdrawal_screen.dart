import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/withdrawal_controller.dart';
import '../controllers/wallet_controller.dart';

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
  void initState() {
    super.initState();
    // Click-diet: prefill the payout number from the account profile and pick
    // the matching MoMo/OM channel when the prefix maps cleanly.
    final phone = ref.read(authControllerProvider).valueOrNull?.user?.phone;
    if (phone != null && phone.isNotEmpty) {
      _account.text = phone;
      _channel = _channelForPhone(phone) ?? _channel;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _account.dispose();
    super.dispose();
  }

  /// Cameroon carrier heuristic: MTN MoMo = 65x–654, 67x, 680–684; Orange
  /// Money = 655–659, 69x, 685–689. Returns null when the number is not
  /// confidently one or the other (foreign format, landline).
  static WithdrawalChannel? _channelForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('237') ? digits.substring(3) : digits;
    if (local.length != 9) return null;
    final prefix3 = int.tryParse(local.substring(0, 3));
    final prefix2 = int.tryParse(local.substring(0, 2));
    if (prefix3 == null || prefix2 == null) return null;
    if (prefix2 == 67 ||
        (prefix3 >= 650 && prefix3 <= 654) ||
        (prefix3 >= 680 && prefix3 <= 684)) {
      return WithdrawalChannel.mtnMomo;
    }
    if (prefix2 == 69 ||
        (prefix3 >= 655 && prefix3 <= 659) ||
        (prefix3 >= 685 && prefix3 <= 689)) {
      return WithdrawalChannel.orangeMoney;
    }
    return null;
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
    // The account password replaces the client-side wallet PIN here: the
    // backend verifies it (bcrypt) inside POST /withdrawals and answers
    // "incorrect password" on mismatch — surfaced verbatim via the controller.
    final password = await showDialog<String>(
      context: context,
      builder: (context) => _WithdrawalConfirmDialog(
        amount: amount,
        channel: _channel,
        accountReference: _account.text.trim(),
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;
    await ref.read(withdrawalControllerProvider.notifier).request(
          amount: amount,
          channel: _channel,
          accountReference: _account.text,
          password: password,
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

    final balance = ref.watch(walletControllerProvider).valueOrNull?.balance ?? 0;
    // The floor comes from platform config `min_withdrawal` (design 21);
    // admins process withdrawals by hand.
    final min = int.tryParse(
          ref
              .watch(platformConfigProvider('min_withdrawal'))
              .valueOrNull ??
              '',
        ) ??
        kDefaultMinWithdrawal;
    final theme = Theme.of(context);
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.withdraw)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t.minWithdrawalNote(amount: formatMoney(min)),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 16),
            // One-tap fills of the available balance (design 21).
            Wrap(
              spacing: 8,
              children: [
                for (final (label, fraction) in [
                  ('25%', 0.25),
                  ('50%', 0.5),
                  (t.all, 1.0),
                ])
                  ActionChip(
                    label: Text(label),
                    onPressed: balance > 0
                        ? () => _amount.text =
                            (balance * fraction).floor().toString()
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FormTextField(
              controller: _amount,
              label: t.amountFcfa,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.currency_exchange),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WithdrawalChannel>(
              initialValue: _channel,
              decoration: InputDecoration(labelText: t.channel),
              items: [
                for (final c in WithdrawalChannel.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _channel = v ?? _channel),
            ),
            // Bank rail specifics — fixed partner bank, slower settlement.
            if (_channel == WithdrawalChannel.bank)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.tanDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.bankTransferNote,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.tanDark),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _account,
              label: _channel == WithdrawalChannel.bank
                  ? t.accountNumberIban
                  : t.accountReferencePhone,
              keyboardType: _channel == WithdrawalChannel.bank
                  ? TextInputType.text
                  : TextInputType.phone,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: _channel == WithdrawalChannel.bank
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? t.required : null
                  : validatePhone,
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
    final min = int.tryParse(
          ref.read(platformConfigProvider('min_withdrawal')).valueOrNull ?? '',
        ) ??
        kDefaultMinWithdrawal;
    if (amount < min) {
      return context.t.minWithdrawalInline(amount: formatMoney(min));
    }
    return null;
  }
}

/// Confirm dialog — recaps the request and collects the account password the
/// backend verifies before accepting the withdrawal (PAY-05).
class _WithdrawalConfirmDialog extends StatefulWidget {
  final int amount;
  final WithdrawalChannel channel;
  final String accountReference;

  const _WithdrawalConfirmDialog({
    required this.amount,
    required this.channel,
    required this.accountReference,
  });

  @override
  State<_WithdrawalConfirmDialog> createState() => _WithdrawalConfirmDialogState();
}

class _WithdrawalConfirmDialogState extends State<_WithdrawalConfirmDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Confirm withdrawal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatMoney(widget.amount)} → ${widget.channel.label} '
            '(${widget.accountReference})',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Account password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Withdraw')),
      ],
    );
  }

  void _confirm() {
    final password = _password.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }
}
