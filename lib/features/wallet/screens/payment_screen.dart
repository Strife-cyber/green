import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../theme/app_colors.dart';
import '../controllers/payment_controller.dart';
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
        .read(paymentControllerProvider.notifier)
        .pay(orderId: widget.orderId, channel: _channel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = ref.watch(paymentOrderProvider(widget.orderId));
    final payment = ref.watch(paymentControllerProvider);

    final body = switch (payment) {
      PaymentIdle() => _buildCheckout(theme, order),
      PaymentInitiating() => const _PaymentLoading(),
      PaymentSuccess(:final result) => _PaymentSuccessView(result: result),
      PaymentFailure(:final message) => _PaymentError(message: message, onRetry: _pay),
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
      builder: (o) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order total', style: theme.textTheme.titleSmall),
                  AmountText(o.totalAmount, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Choose payment channel', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _ChannelCard(
            title: 'MTN Mobile Money',
            subtitle: 'Pay with your MTN MoMo wallet',
            icon: Icons.phone_android,
            selected: _channel == PaymentChannel.mtnMomo,
            onTap: () => setState(() => _channel = PaymentChannel.mtnMomo),
          ),
          const SizedBox(height: 8),
          _ChannelCard(
            title: 'Orange Money',
            subtitle: 'Pay with your Orange wallet',
            icon: Icons.smartphone,
            selected: _channel == PaymentChannel.orangeMoney,
            onTap: () => setState(() => _channel = PaymentChannel.orangeMoney),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _pay,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Pay'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
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

class _PaymentSuccessView extends StatelessWidget {
  final PaymentResult result;

  const _PaymentSuccessView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.green, size: 72),
            const SizedBox(height: 16),
            Text('Payment successful', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (result.reference != null)
              Text('Reference: ${result.reference}', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.buyerOrders),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
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

  const _ChannelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.green : AppColors.tan, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
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
    );
  }
}
