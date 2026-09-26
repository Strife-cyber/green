import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Own-profile editing (AUTH-01, DEL-04). Saves via [UserRepository.updateProfile];
/// the screen confirms with a snackbar since the auth session has no public
/// in-place user setter.
class ProfileEditController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    // Resets leftover save state on account switch.
    ref.watch(currentUserIdProvider);
    return const AsyncData(null);
  }

  /// Save the profile. Returns `true` on success.
  Future<bool> save(UpdateProfileInput input) async {
    state = const AsyncLoading();
    try {
      await ref.read(userRepositoryProvider).updateProfile(input);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final profileEditControllerProvider =
    NotifierProvider<ProfileEditController, AsyncValue<void>>(ProfileEditController.new);
