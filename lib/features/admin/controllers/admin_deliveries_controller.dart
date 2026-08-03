import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery.dart';
import '../../../data/repositories/providers.dart';

/// In-flight deliveries (assigned but not yet delivered) for admin oversight
/// (ADM-05, DEL-02/03).
class AdminDeliveriesController extends AsyncNotifier<List<Delivery>> {
  @override
  Future<List<Delivery>> build() => ref.watch(adminRepositoryProvider).activeDeliveries();

  /// Re-fetches the list (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final adminDeliveriesControllerProvider =
    AsyncNotifierProvider<AdminDeliveriesController, List<Delivery>>(AdminDeliveriesController.new);
