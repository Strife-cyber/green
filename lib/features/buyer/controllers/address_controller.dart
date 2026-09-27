import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// CRUD for the buyer's saved delivery addresses (BUY-08). Each mutation
/// reloads the list so screens always reflect the persisted state. Scoped to
/// the signed-in user — a logout → login refetches instead of serving the
/// previous account's addresses.
class AddressController extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(addressRepositoryProvider).list();
  }

  Future<void> add(CreateAddressInput input) async {
    await ref.read(addressRepositoryProvider).create(input);
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the screen.
    }
  }

  Future<void> edit(String id, CreateAddressInput input) async {
    await ref.read(addressRepositoryProvider).update(id, input);
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the screen.
    }
  }

  Future<void> delete(String id) async {
    await ref.read(addressRepositoryProvider).delete(id);
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the screen.
    }
  }

  Future<void> setDefault(String id) async {
    await ref.read(addressRepositoryProvider).setDefault(id);
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the screen.
    }
  }
}

final addressControllerProvider =
    AsyncNotifierProvider<AddressController, List<Address>>(
  AddressController.new,
);
