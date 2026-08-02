import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat.dart';
import '../../../data/repositories/providers.dart';

/// The current user's chat threads (CHAT-01). Loaded from the chat repository
/// and exposed as an `AsyncValue` so screens reuse [AsyncView].
class ChatThreadListController extends AsyncNotifier<List<ChatThread>> {
  @override
  Future<List<ChatThread>> build() => ref.watch(chatRepositoryProvider).threads();

  /// Re-fetches the thread list, e.g. after opening a thread.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final chatThreadListControllerProvider =
    AsyncNotifierProvider<ChatThreadListController, List<ChatThread>>(
  ChatThreadListController.new,
);
