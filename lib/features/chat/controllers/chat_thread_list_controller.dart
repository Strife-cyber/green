import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The current user's chat threads (CHAT-01). Loaded from the chat repository
/// and merged with live `message:created` / `message:read` socket events so a
/// new message bumps a preview + unread badge and reading clears it, without a
/// refetch per event.
class ChatThreadListController extends AsyncNotifier<List<ChatThread>> {
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;

  @override
  Future<List<ChatThread>> build() async {
    final socket = ref.read(socketServiceProvider);
    // Connect (awaiting session restore on cold start) — the root namespace
    // already carries the auth handshake. No rooms are joined here: the list
    // wants events for every thread, not one.
    unawaited(socket.connectWhenAuthed(ref, namespace: SocketService.chatNamespace));
    _messageSub?.cancel();
    _messageSub = socket
        .events('message:created', namespace: SocketService.chatNamespace)
        .listen(_onMessageCreated);
    _readSub?.cancel();
    _readSub = socket
        .events('message:read', namespace: SocketService.chatNamespace)
        .listen(_onMessageRead);
    ref.onDispose(() {
      _messageSub?.cancel();
      _readSub?.cancel();
    });
    return ref.read(chatRepositoryProvider).threads();
  }

  /// Re-fetches the thread list, e.g. after opening a thread or pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  void _onMessageCreated(Map<String, dynamic> data) {
    final payload = data['message'] is Map
        ? Map<String, dynamic>.from(data['message'] as Map)
        : data;
    try {
      final message = ChatMessage.fromJson(payload);
      final current = state.value;
      if (current == null) return;
      final currentUserId =
          ref.read(authControllerProvider).valueOrNull?.user?.id ?? '';
      final mine = message.isMine(currentUserId);
      final threads = [...current];
      final index = threads.indexWhere((t) => t.id == message.threadId);
      if (index == -1) {
        // A brand-new thread we haven't fetched yet — refetch once.
        ref.invalidateSelf();
        return;
      }
      final thread = threads[index];
      threads[index] = thread.copyWith(
        lastMessage: ChatThreadLastMessage(
          content: message.content,
          type: message.type,
          sentAt: message.sentAt,
          mine: mine,
        ),
        unreadCount: thread.unreadCount + (mine ? 0 : 1),
        updatedAt: message.sentAt,
      );
      threads.sort(_byRecency);
      state = AsyncData(threads);
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  void _onMessageRead(Map<String, dynamic> data) {
    try {
      final threadId = data['threadId'] as String?;
      final userId = data['userId'] as String?;
      final current = state.value;
      if (threadId == null || current == null) return;
      // Only the current user reading clears the badge — the counterparty
      // reading their own copy of the thread doesn't change our unread count.
      final currentUserId =
          ref.read(authControllerProvider).valueOrNull?.user?.id ?? '';
      if (userId != currentUserId) return;
      final index = current.indexWhere((t) => t.id == threadId);
      if (index == -1) return;
      final threads = [...current];
      threads[index] = threads[index].copyWith(unreadCount: 0);
      state = AsyncData(threads);
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  static int _byRecency(ChatThread a, ChatThread b) {
    final ta = a.updatedAt ?? a.lastMessage?.sentAt ?? a.createdAt ?? DateTime(0);
    final tb = b.updatedAt ?? b.lastMessage?.sentAt ?? b.createdAt ?? DateTime(0);
    return tb.compareTo(ta);
  }
}

final chatThreadListControllerProvider =
    AsyncNotifierProvider<ChatThreadListController, List<ChatThread>>(
  ChatThreadListController.new,
);
