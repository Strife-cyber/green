import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Submits a new driver account request (D6). The screen watches [state] to
/// drive the submit button spinner and reads the returned `bool` for the
/// success snackbar.
class AdminCreateDriverController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    // Resets leftover submit state on account switch.
    ref.watch(currentUserIdProvider);
    return const AsyncData(null);
  }

  /// Creates the driver account. Returns the backend-generated temporary
  /// password on success (so the screen can show it once, for sharing with the
  /// driver), or null on failure.
  Future<String?> submit(CreateDriverInput input) async {
    state = const AsyncLoading();
    try {
      final tempPassword = await ref.read(adminRepositoryProvider).createDriver(input);
      state = const AsyncData(null);
      return tempPassword;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final adminCreateDriverControllerProvider =
    NotifierProvider<AdminCreateDriverController, AsyncValue<void>>(AdminCreateDriverController.new);
