import 'package:flutter_test/flutter_test.dart';

import 'package:green/data/mock/mock_repositories.dart';
import 'package:green/data/mock/mock_store.dart';
import 'package:green/data/models/enums.dart';

void main() {
  group('MockDeliveryRepository delivery confirmation (DEL-07)', () {
    test('one-tap confirm when the order is not code-required', () async {
      final store = MockStore();
      final repo = MockDeliveryRepository(store);
      // o-1 is PENDING + unpaid, total 3 500 FCFA — below the code threshold.
      final delivery = await repo.assign('o-1', 'u-driver-1');
      expect(delivery.isPickupConfirmed, isFalse);
      expect(delivery.isDelivered, isFalse);
      expect(delivery.codeRequired, isFalse);

      // Driver picks up → order flips to SHIPPED (driver action, not seller).
      final picked = await repo.pickup(delivery.id);
      expect(picked.isPickupConfirmed, isTrue);
      expect(picked.isDelivered, isFalse);
      expect(
        store.orders.firstWhere((o) => o.id == 'o-1').status,
        OrderStatus.shipped,
      );

      // Driver completes the hand-off: a code is issued to the buyer's email,
      // but the order is NOT delivered yet. The code is not stored for the
      // demo when no code is required (one-tap confirm).
      final completed = await repo.complete(delivery.id);
      expect(completed.isDelivered, isFalse);
      expect(completed.confirmationCodeIssued, isTrue);
      expect(store.deliveryCodes.containsKey(delivery.id), isFalse);

      // The buyer confirms with a one-tap "Got it" (null code).
      final confirmed = await repo.confirm(delivery.id);
      expect(confirmed.isDelivered, isTrue);
      expect(
        store.orders.firstWhere((o) => o.id == 'o-1').status,
        OrderStatus.delivered,
      );
    });

    test('code-required order needs the 6-digit code', () async {
      final store = MockStore();
      final repo = MockDeliveryRepository(store);
      // o-4 total 28 500 FCFA (> 25 000) — the buyer must enter a code.
      final delivery = await repo.assign('o-4', 'u-driver-1');
      expect(delivery.codeRequired, isTrue);

      // A code-required order cannot be confirmed before the driver completes
      // the hand-off (no code issued yet).
      await expectLater(repo.confirm(delivery.id), throwsException);
      await expectLater(repo.confirm(delivery.id, code: '482913'), throwsException);

      await repo.pickup(delivery.id);
      final completed = await repo.complete(delivery.id);
      expect(completed.confirmationCodeIssued, isTrue);
      expect(store.deliveryCodes[delivery.id], '482913');

      // A wrong code is rejected; the one-tap path (null code) is too.
      await expectLater(repo.confirm(delivery.id, code: '000000'), throwsException);
      await expectLater(repo.confirm(delivery.id), throwsException);

      // The buyer's code marks the delivery delivered and burns the code.
      final confirmed = await repo.confirm(delivery.id, code: '482913');
      expect(confirmed.isDelivered, isTrue);
      expect(store.deliveryCodes.containsKey(delivery.id), isFalse);
    });
  });
}
