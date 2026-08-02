import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat.dart';
import '../../../data/repositories/providers.dart';

/// Read-only access to a chat thread's messages for admin oversight (ADM-12).
class AdminChatController extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String threadId) =>
      ref.watch(adminRepositoryProvider).chatMessages(threadId);
}

final adminChatControllerProvider =
    AsyncNotifierProvider.family<AdminChatController, List<ChatMessage>, String>(AdminChatController.new);
