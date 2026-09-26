import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/withdrawal_repository.dart';
import '../../auth/controllers/auth_controller.dart';

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
  WithdrawalState build() {
    // Resets leftover submit/error state on account switch.
    ref.watch(currentUserIdProvider);
    return const WithdrawalIdle();
  }

  Future<void> request({
    required int amount,
    required WithdrawalChannel channel,
    required String accountReference,
    required String password,
  }) async {
    state = const WithdrawalSubmitting();
    try {
      await ref.read(withdrawalRepositoryProvider).request(
            WithdrawalRequest(
              amount: amount,
              channel: channel,
              accountReference: accountReference.trim(),
              password: password,
            ),
          );
      state = const WithdrawalDone();
    } catch (error) {
      state = WithdrawalError(_messageFor(error));
    }
  }

  /// Surfaces the server's own message verbatim ("incorrect password",
  /// "Minimum withdrawal is X FCFA", insufficient balance, …); opaque errors
  /// fall back to a generic line.
  static String _messageFor(Object error) {
    if (error is ApiException && error.message.isNotEmpty) return error.message;
    final text = error.toString().trim();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) return text.substring(prefix.length);
    return text.isEmpty
        ? 'Could not submit the withdrawal. Please try again.'
        : text;
  }
}

final withdrawalControllerProvider =
    NotifierProvider<WithdrawalController, WithdrawalState>(WithdrawalController.new);
