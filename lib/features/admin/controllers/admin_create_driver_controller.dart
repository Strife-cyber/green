import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/providers.dart';

/// Submits a new driver account request (D6). The screen watches [state] to
/// drive the submit button spinner and reads the returned `bool` for the
/// success snackbar.
class AdminCreateDriverController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Creates the driver account. Returns `true` on success.
  Future<bool> submit(CreateDriverInput input) async {
    state = const AsyncLoading();
    try {
      await ref.read(adminRepositoryProvider).createDriver(input);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final adminCreateDriverControllerProvider =
    NotifierProvider<AdminCreateDriverController, AsyncValue<void>>(AdminCreateDriverController.new);
