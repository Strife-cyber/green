import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../buyer/controllers/buyer_order_list_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/wallet_controller.dart';
import '../services/wallet_pin_service.dart';
import '../widgets/wallet_pin_dialogs.dart';

/// The order whose payment is being settled.
final paymentOrderProvider = FutureProvider.family<Order, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).get(orderId),
);

/// Mobile-money checkout for an order (PAY-01/02).
class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentChannel _channel = PaymentChannel.mtnMomo;

  /// Wallet-PIN gate before contacting mobile money (PAY-10). Client-side
  /// enforcement for the demo — PIN verification moves server-side at the
  /// payment hand-off.
  Future<void> _pay() async {
    final authorized = await authorizeWalletAction(
      context,
      ref.read(walletPinServiceProvider),
    );
    if (!authorized || !mounted) return;
    ref
        .read(paymentControllerProvider(widget.orderId).notifier)
        .pay(orderId: widget.orderId, channel: _channel);
  }

  /// Other unpaid order ids (excluding the one this screen is paying). The
  /// buyer order list is what the multi-order checkout pushes through — after
  /// paying order 1 of 2, this still lists order 2 so we can continue.
  List<String> _remainingUnpaidOrderIds() {
    final orders =
        ref.read(buyerOrderListControllerProvider).valueOrNull ?? const <Order>[];
    return [
      for (final o in orders)
        if (o.paymentStatus == PaymentStatus.unpaid &&
            o.status != OrderStatus.cancelled &&
            o.id != widget.orderId)
          o.id,
    ];
  }

  /// Continue paying the next unpaid order, or finish when there are none.
  void _continue() {
    final remaining = _remainingUnpaidOrderIds();
    ref.invalidate(buyerOrderListControllerProvider);
    ref.invalidate(walletControllerProvider);
    if (remaining.isNotEmpty) {
      context.go(AppRoutes.payment(remaining.first));
    } else {
      context.go(AppRoutes.buyerOrders);
    }
  }

  /// Straight to the Orders tab (fresh data), skipping any unpaid orders.
  void _finish() {
    ref.invalidate(buyerOrderListControllerProvider);
    ref.invalidate(walletControllerProvider);
    context.go(AppRoutes.buyerOrders);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = ref.watch(paymentOrderProvider(widget.orderId));
    final payment = ref.watch(paymentControllerProvider(widget.orderId));
    // Watch the buyer list so payment can continue through any other unpaid
    // orders created during the same checkout (kept invisible: this screen
    // shows only the one order being paid).
    final unpaidOrders = ref.watch(buyerOrderListControllerProvider).valueOrNull ??
        const <Order>[];
    final unpaidIds = [
      for (final o in unpaidOrders)
        if (o.paymentStatus == PaymentStatus.unpaid &&
            o.status != OrderStatus.cancelled)
          o.id,
    ];
    final remaining = [for (final id in unpaidIds) if (id != widget.orderId) id];

    final body = switch (payment) {
      PaymentIdle() => _buildCheckout(theme, order),
      PaymentInitiating() => const _PaymentLoading(),
      PaymentSuccess(:final result) => _PaymentSuccessView(
          result: result,
          orderId: widget.orderId,
          nextOrderId: remaining.isEmpty ? null : remaining.first,
          remainingCount: remaining.length,
          onPayNext: _continue,
          onFinish: _finish,
        ),
      PaymentFailure(:final message) =>
        _PaymentError(message: message, onRetry: _pay),
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Payment')),
      body: body,
    );
  }

  Widget _buildCheckout(ThemeData theme, AsyncValue<Order> order) {
    return AsyncView<Order>(
      value: order,
      onRetry: () => ref.invalidate(paymentOrderProvider(widget.orderId)),
      builder: (o) {
        // Last-line guard: even if a Pay-now entry point raced a status
        // change, a cancelled or already-paid order must never be charged.
        final payable = o.paymentStatus == PaymentStatus.unpaid &&
            o.status != OrderStatus.cancelled;
        final wallet = ref.watch(walletControllerProvider).valueOrNull;
        final walletCovers =
            wallet != null && wallet.balance >= o.totalAmount;
        final phone = ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.phone;
        final hasNumber = phone != null && phone.isNotEmpty;
        return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.t.orderTotal, style: theme.textTheme.titleSmall),
                  AmountText(o.totalAmount, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _PhoneCard(),
          const SizedBox(height: 16),
          Text(context.t.choosePaymentChannel,
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          // Greenish Wallet pays from the escrow-backed balance — greyed out
          // with the missing amount when it can't cover the order (PAY-01).
          _ChannelCard(
            title: context.t.greenishWallet,
            subtitle: walletCovers
                ? context.t.walletBalanceLine(
                    balance: formatMoney(wallet.balance))
                : context.t.walletBalanceInsufficient(
                    balance: formatMoney(wallet?.balance ?? 0)),
            icon: Icons.account_balance_wallet_outlined,
            selected: _channel == PaymentChannel.wallet,
            enabled: walletCovers,
            onTap: () => setState(() => _channel = PaymentChannel.wallet),
          ),
          const SizedBox(height: 8),
          _ChannelCard(
            title: 'MTN Mobile Money',
            subtitle: hasNumber
                ? context.t.payWithMtn(phone: phone)
                : context.t.addMtnNumber,
            icon: Icons.phone_android,
            selected: _channel == PaymentChannel.mtnMomo,
            onTap: () => setState(() => _channel = PaymentChannel.mtnMomo),
          ),
          const SizedBox(height: 8),
          _ChannelCard(
            title: 'Orange Money',
            subtitle: hasNumber
                ? context.t.payWithOrange(phone: phone)
                : context.t.addOrangeNumber,
            icon: Icons.smartphone,
            selected: _channel == PaymentChannel.orangeMoney,
            onTap: () => setState(() => _channel = PaymentChannel.orangeMoney),
          ),
          const SizedBox(height: 24),
          if (!payable) ...[
            Text(
              'This order can no longer be paid.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: payable ? _pay : null,
            icon: const Icon(Icons.lock_outline),
            label: Text(context.t.payNow),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
        );
      },
    );
  }
}

class _PaymentLoading extends StatelessWidget {
  const _PaymentLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Contacting mobile money…'),
        ],
      ),
    );
  }
}

/// Post-payment confirmation (design 19): escrow explainer, the `GRN-…`
/// receipt number, the 6-digit delivery code the driver will ask for, and
/// track/download CTAs.
class _PaymentSuccessView extends ConsumerWidget {
  final PaymentResult result;
  final String orderId;
  final String? nextOrderId;
  final int remainingCount;
  final VoidCallback onPayNext;
  final VoidCallback onFinish;

  const _PaymentSuccessView({
    required this.result,
    required this.orderId,
    this.nextOrderId,
    this.remainingCount = 0,
    required this.onPayNext,
    required this.onFinish,
  });

  /// Downloads the receipt PDF via `GET /receipts/:id/download` (the app
  /// resolves the receipt id from the order first).
  Future<void> _downloadReceipt(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref
          .read(receiptRepositoryProvider)
          .downloadOrderPdf(orderId);
      if (!context.mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.receiptNotReady)),
        );
        return;
      }
      await downloadFile(
        bytes: Uint8List.fromList(bytes),
        filename: 'receipt-$orderId.pdf',
        mimeType: 'application/pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.downloadFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    final hasNext = nextOrderId != null && remainingCount > 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.green, size: 72),
            const SizedBox(height: 16),
            Text(t.paymentSuccessful,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            // Escrow explainer — the money is held until delivery is
            // confirmed (design 19).
            Text(
              t.escrowExplainer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            Text(
              '${t.receiptNumber}: ${result.receiptNumber ?? result.reference ?? '—'}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (result.deliveryCode != null) ...[
              const SizedBox(height: 12),
              Text(t.deliveryCodeLabel, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              // Big spaced digits — the buyer reads these to the driver.
              Text(
                result.deliveryCode!.split('').join(' '),
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDark,
                ),
              ),
            ],
            if (hasNext) ...[
              const SizedBox(height: 8),
              Text(
                t.unpaidOrdersLeft(count: remainingCount),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.tanDark),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: hasNext ? onPayNext : onFinish,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14)),
              child: Text(
                hasNext
                    ? t.payNextOrder(count: remainingCount)
                    : t.done,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.deliveryTracking(orderId)),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: Text(t.trackThisDelivery),
                ),
                TextButton.icon(
                  onPressed: () => _downloadReceipt(context, ref),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(t.downloadReceipt),
                ),
              ],
            ),
            if (hasNext)
              TextButton(onPressed: onFinish, child: Text(t.doneForNow)),
          ],
        ),
      ),
    );
  }
}

/// Shows which mobile-money number will be charged (the buyer's profile phone)
/// and lets them see / edit it before paying.
class _PhoneCard extends ConsumerWidget {
  const _PhoneCard();

  Future<void> _editPhone(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => _PhoneDialog(initialPhone: user?.phone ?? ''),
    );
    if (phone == null || phone.isEmpty || !context.mounted) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(UpdateProfileInput(phone: phone));
      // The auth session owns the profile — refetch it to reflect the change.
      ref.invalidate(authControllerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment number updated')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your phone number.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final phone = user?.phone;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_android, color: AppColors.green),
        title: Text('Charged to', style: theme.textTheme.bodySmall),
        subtitle: Text(
          (phone == null || phone.isEmpty)
              ? 'No number on your profile — add one'
              : phone,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          tooltip: 'Edit number',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _editPhone(context, ref),
        ),
      ),
    );
  }
}

class _PhoneDialog extends StatefulWidget {
  final String initialPhone;

  const _PhoneDialog({required this.initialPhone});

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mobile money number'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone (e.g. 6XX XXX XXX)',
          hintText: '650 123 456',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PaymentError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PaymentError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.orange, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// False renders the channel greyed out and untappable (e.g. wallet balance
  /// that can't cover the order).
  final bool enabled;

  const _ChannelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.green : AppColors.tan, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.green : AppColors.tanDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.green : AppColors.tan,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
