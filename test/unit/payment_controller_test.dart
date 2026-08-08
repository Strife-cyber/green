import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:green/data/repositories/payment_repository.dart';
import 'package:green/data/repositories/providers.dart';
import 'package:green/features/wallet/controllers/payment_controller.dart';

/// Payment flow state is keyed per order (PAY-01/02) — one order's success
/// must never leak into another order's checkout screen and skip the network
/// call that `initiate()` should make.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [useMocksProvider.overrideWithValue(true)],
      );

  test('paying order A lands in success; order B starts idle', () async {
    final container = makeContainer();

    // Pay for order A → success.
    await container
        .read(paymentControllerProvider('o-a').notifier)
        .pay(orderId: 'o-a', channel: PaymentChannel.mtnMomo);
    expect(container.read(paymentControllerProvider('o-a')), isA<PaymentSuccess>());

    // A different order starts fresh — no stale success, no skipped request.
    expect(container.read(paymentControllerProvider('o-b')), isA<PaymentIdle>());
  });

  test('paying again for the same order transitions through initiating', () async {
    final container = makeContainer();

    final future = container
        .read(paymentControllerProvider('o-a').notifier)
        .pay(orderId: 'o-a', channel: PaymentChannel.orangeMoney);

    // Immediately after initiating, the state is loading (not a stale result).
    expect(container.read(paymentControllerProvider('o-a')), isA<PaymentInitiating>());

    await future;
    expect(container.read(paymentControllerProvider('o-a')), isA<PaymentSuccess>());
  });

  test('the same order keeps its success across reads (no state reset)', () async {
    final container = makeContainer();

    await container
        .read(paymentControllerProvider('o-a').notifier)
        .pay(orderId: 'o-a', channel: PaymentChannel.mtnMomo);
    expect(container.read(paymentControllerProvider('o-a')), isA<PaymentSuccess>());
    // Reading again must not reset it — the screen relies on a stable result.
    expect(container.read(paymentControllerProvider('o-a')), isA<PaymentSuccess>());
  });
}
