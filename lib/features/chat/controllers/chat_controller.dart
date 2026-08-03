import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Messages and composer state for a single chat thread (CHAT-02/03).
class ChatState {
  final List<ChatMessage> messages;
  final bool loading;
  final String? error;
  final bool sending;

  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.sending = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    String? error,
    bool? sending,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        sending: sending ?? this.sending,
      );
}

/// Drives one thread: loads history, merges live `chat.messageCreated` socket
/// events, sends text/image/voice messages and marks the thread read. All
/// repository and socket calls are guarded so a missing backend is harmless.
class ChatController extends FamilyNotifier<ChatState, String> {
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  bool _disposed = false;

  @override
  ChatState build(String threadId) {
    _disposed = false;
    final socket = ref.read(socketServiceProvider);
    final token = ref.read(authControllerProvider).valueOrNull?.session?.accessToken;
    // Join the thread room so the server streams live messages to this socket
    // (auto re-joined on reconnect).
    socket.connect(token: token ?? '', namespace: SocketService.chatNamespace);
    socket.joinRoom(SocketService.chatNamespace, {'threadId': threadId});
    _socketSub = socket
        .events('message:created', namespace: SocketService.chatNamespace)
        .listen(_onMessageCreated);
    ref.onDispose(() {
      _disposed = true;
      _socketSub?.cancel();
    });
    unawaited(_load());
    unawaited(markRead());
    return const ChatState(loading: true);
  }

  /// Loads history, merging any live messages already received.
  Future<void> _load() async {
    try {
      final history = await ref.read(chatRepositoryProvider).messages(arg);
      if (_disposed) return;
      final byId = {for (final m in history) m.id: m};
      for (final m in state.messages) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      state = ChatState(messages: merged);
    } catch (error) {
      if (_disposed) return;
      state = ChatState(messages: state.messages, error: error.toString());
    }
  }

  void _onMessageCreated(Map<String, dynamic> data) {
    final payload = data['message'] is Map
        ? Map<String, dynamic>.from(data['message'] as Map)
        : data;
    try {
      final message = ChatMessage.fromJson(payload);
      if (message.threadId != arg) return;
      if (state.messages.any((m) => m.id == message.id)) return;
      state = state.copyWith(messages: [...state.messages, message]);
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  Future<void> sendText(String text) => _send(
        SendMessageInput(content: text.trim(), type: MessageType.text),
      );

  Future<void> sendImage(String path) => _send(
        SendMessageInput(content: '', type: MessageType.image, filePath: path),
      );

  Future<void> sendVoice(String path) => _send(
        SendMessageInput(content: '', type: MessageType.voice, filePath: path),
      );

  Future<void> _send(SendMessageInput input) async {
    if (state.sending) return;
    state = state.copyWith(sending: true);
    try {
      final sent = await ref.read(chatRepositoryProvider).send(arg, input);
      if (_disposed) return;
      state = state.copyWith(messages: [...state.messages, sent], sending: false);
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(sending: false, error: error.toString());
    }
  }

  /// Best-effort read receipt: tells the server (and the other party) the
  /// thread was opened. Never throws.
  Future<void> markRead() async {
    ref.read(socketServiceProvider).emit(
          'message:read',
          {'threadId': arg},
          namespace: SocketService.chatNamespace,
        );
    try {
      await ref.read(chatRepositoryProvider).markRead(arg);
    } catch (_) {
      // Ignore — the backend may not be reachable.
    }
  }
}

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(
  ChatController.new,
);
