import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';

/// All DRIVER accounts, for admin oversight (ADM-08, D6).
class AdminDriversController extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() => ref.watch(adminRepositoryProvider).drivers();

  /// Re-fetches the list (pull-to-refresh / after creating a driver).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final adminDriversControllerProvider =
    AsyncNotifierProvider<AdminDriversController, List<User>>(AdminDriversController.new);

/// All orders for the admin's assign-delivery picker.
final assignableOrdersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(adminRepositoryProvider).orders(),
);
