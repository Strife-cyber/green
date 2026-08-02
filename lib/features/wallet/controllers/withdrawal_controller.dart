import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/withdrawal_repository.dart';

/// Flow state of a wallet withdrawal request.
sealed class WithdrawalState {
  const WithdrawalState();
}

class WithdrawalIdle extends WithdrawalState {
  const WithdrawalIdle();
}

class WithdrawalSubmitting extends WithdrawalState {
  const WithdrawalSubmitting();
}

class WithdrawalDone extends WithdrawalState {
  const WithdrawalDone();
}

class WithdrawalError extends WithdrawalState {
  final String message;
  const WithdrawalError(this.message);
}

/// Submits a wallet withdrawal request (PAY-05).
class WithdrawalController extends Notifier<WithdrawalState> {
  @override
  WithdrawalState build() => const WithdrawalIdle();

  Future<void> request({
    required int amount,
    required WithdrawalChannel channel,
    required String accountReference,
  }) async {
    state = const WithdrawalSubmitting();
    try {
      await ref.read(withdrawalRepositoryProvider).request(
            WithdrawalRequest(
              amount: amount,
              channel: channel,
              accountReference: accountReference.trim(),
            ),
          );
      state = const WithdrawalDone();
    } catch (_) {
      state = const WithdrawalError('Could not submit the withdrawal. Please try again.');
    }
  }
}

final withdrawalControllerProvider =
    NotifierProvider<WithdrawalController, WithdrawalState>(WithdrawalController.new);
