import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/withdrawal.dart';
import '../../../data/repositories/providers.dart';

/// Withdrawal requests awaiting admin processing (PAY-05).
class AdminWithdrawalsController extends AsyncNotifier<List<Withdrawal>> {
  @override
  Future<List<Withdrawal>> build() => ref.watch(adminRepositoryProvider).pendingWithdrawals();

  /// Process a withdrawal (pay out), then re-fetch the pending list.
  Future<void> process(String id) async {
    await ref.read(adminRepositoryProvider).processWithdrawal(id);
    ref.invalidateSelf();
  }

  /// Reject a withdrawal, then re-fetch the pending list.
  Future<void> reject(String id) async {
    await ref.read(adminRepositoryProvider).processWithdrawal(id, reject: true);
    ref.invalidateSelf();
  }
}

final adminWithdrawalsControllerProvider =
    AsyncNotifierProvider<AdminWithdrawalsController, List<Withdrawal>>(AdminWithdrawalsController.new);
