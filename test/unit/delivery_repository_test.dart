import 'package:flutter_test/flutter_test.dart';

import 'package:green/data/mock/mock_repositories.dart';
import 'package:green/data/mock/mock_store.dart';

void main() {
  group('MockDeliveryRepository delivery confirmation (DEL-07)', () {
    test('complete issues a code without delivering; confirm delivers', () async {
      final store = MockStore();
      final repo = MockDeliveryRepository(store);

      final delivery = await repo.assign('o-1', 'u-driver-1');
      expect(delivery.isPickupConfirmed, isFalse);
      expect(delivery.isDelivered, isFalse);

      // Driver completes the hand-off: a code is issued, but the order is NOT
      // delivered until the buyer confirms it (backend contract).
      final completed = await repo.complete(delivery.id);
      expect(completed.isPickupConfirmed, isTrue);
      expect(completed.isDelivered, isFalse);
      expect(store.deliveryCodes[delivery.id], '482913');

      // A wrong code is rejected.
      await expectLater(repo.confirm(delivery.id, '000000'), throwsException);

      // The buyer's code marks the delivery delivered and burns the code.
      final confirmed = await repo.confirm(delivery.id, '482913');
      expect(confirmed.isDelivered, isTrue);
      expect(store.deliveryCodes.containsKey(delivery.id), isFalse);
    });

    test('confirm before a code is issued is rejected', () async {
      final store = MockStore();
      final repo = MockDeliveryRepository(store);

      final delivery = await repo.assign('o-1', 'u-driver-1');
      await expectLater(repo.confirm(delivery.id, '482913'), throwsException);
    });
  });
}
