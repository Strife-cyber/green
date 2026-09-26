import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Messages, composer and realtime state for a single chat thread (CHAT-02/03).
class ChatState {
  final List<ChatMessage> messages;
  final bool loading;
  final String? error;
  final bool sending;

  /// Whether the counterparty is typing right now (drives the typing bubble).
  final bool counterpartyTyping;

  /// A message from the realtime gateway (`chat:error`) — surfaced subtly,
  /// never a crash.
  final String? realtimeError;

  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.sending = false,
    this.counterpartyTyping = false,
    this.realtimeError,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    String? error,
    bool? sending,
    bool? counterpartyTyping,
    String? realtimeError,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        sending: sending ?? this.sending,
        counterpartyTyping: counterpartyTyping ?? this.counterpartyTyping,
        realtimeError: realtimeError ?? this.realtimeError,
      );
}

/// Drives one thread: loads history, merges live `message:created` / `message:read`
/// / `typing` socket events, sends text/image/voice messages optimistically and
/// marks the thread read. All repository and socket calls are guarded so a
/// missing backend is harmless.
class ChatController extends FamilyNotifier<ChatState, String> {
  /// How long after the last keystroke before the typing indicator turns off,
  /// and the minimum gap between two `typing` emits while still typing.
  static const Duration typingEmitInterval = Duration(milliseconds: 500);

  /// Auto-clear for the counterparty's typing bubble after a few seconds of
  /// silence, so a dropped `typing:false` never sticks the indicator on.
  static const Duration typingInactivity = Duration(seconds: 3);

  StreamSubscription<Map<String, dynamic>>? _socketSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _errorSub;
  Timer? _typingDebounce;
  Timer? _typingInactivity;
  DateTime _lastTypingEmit = DateTime.fromMillisecondsSinceEpoch(0);
  bool _typingActive = false;
  bool _disposed = false;
  int _optimisticSeq = 0;

  String get _currentUserId =>
      ref.read(authControllerProvider).valueOrNull?.user?.id ?? '';

  @override
  ChatState build(String threadId) {
    _disposed = false;
    final socket = ref.read(socketServiceProvider);
    // Connect (awaiting session restore on cold start, so the token is never
    // empty) and join the thread room — rooms are re-joined automatically on
    // any reconnect.
    unawaited(socket.connectWhenAuthed(ref, namespace: SocketService.chatNamespace));
    socket.joinRoom(SocketService.chatNamespace, {'threadId': threadId});
    _socketSub = socket
        .events('message:created', namespace: SocketService.chatNamespace)
        .listen(_onMessageCreated);
    _readSub = socket
        .events('message:read', namespace: SocketService.chatNamespace)
        .listen(_onMessageRead);
    _typingSub = socket
        .events('typing', namespace: SocketService.chatNamespace)
        .listen(_onTyping);
    _errorSub = socket
        .events('chat:error', namespace: SocketService.chatNamespace)
        .listen(_onChatError);
    ref.onDispose(() {
      _disposed = true;
      _socketSub?.cancel();
      _readSub?.cancel();
      _typingSub?.cancel();
      _errorSub?.cancel();
      _typingDebounce?.cancel();
      _typingInactivity?.cancel();
      stopTyping();
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
      state = state.copyWith(messages: merged, loading: false, error: null);
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  /// Re-fetches history — used by pull-to-refresh. Live messages are preserved.
  Future<void> refresh() => _load();

  void _onMessageCreated(Map<String, dynamic> data) {
    final payload = data['message'] is Map
        ? Map<String, dynamic>.from(data['message'] as Map)
        : data;
    try {
      final message = ChatMessage.fromJson(payload);
      if (message.threadId != arg) return;
      final messages = [...state.messages];
      final existing = messages.indexWhere((m) => m.id == message.id);
      if (existing != -1) {
        // Re-echo of a message we already hold (e.g. our own POST) — merge any
        // newer delivery timestamps the server now knows about.
        final current = messages[existing];
        messages[existing] = current.copyWith(
          deliveredAt: message.deliveredAt ?? current.deliveredAt,
          readAt: message.readAt ?? current.readAt,
        );
      } else {
        // The server echo of an optimistic message — swap it in place so we
        // never show both the pending bubble and the real one.
        final pending = messages.indexWhere(
            (m) => m.pending && _matchesOptimistic(m, message));
        if (pending != -1) {
          messages[pending] = message;
        } else {
          messages.add(message);
        }
      }
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      state = state.copyWith(messages: messages, sending: false);
      // Keep the open thread read: a counterparty message landing while we're
      // here should clear the badge and flip their ticks without waiting for a
      // manual reopen.
      if (!message.isMine(_currentUserId)) unawaited(markRead());
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  /// Matches a pending optimistic message to the server echo that acks it.
  /// Text is matched on content; media on type + send window, because the local
  /// file path in [ChatMessage.fileUrl] never survives the upload.
  bool _matchesOptimistic(ChatMessage pending, ChatMessage echo) {
    if (!echo.isMine(_currentUserId)) return false;
    if (pending.type != echo.type) return false;
    if (echo.type == MessageType.text) return pending.content == echo.content;
    return pending.sentAt.difference(echo.sentAt).inSeconds.abs() <= 10;
  }

  void _onMessageRead(Map<String, dynamic> data) {
    try {
      if (data['threadId'] != arg) return;
      final userId = data['userId'] as String?;
      // Only the counterparty reading flips OUR sent ticks to blue.
      if (userId == null || userId == _currentUserId) return;
      final ids = _readMessageIds(data);
      if (ids.isEmpty) return;
      final readAt = DateTime.tryParse(data['readAt'] as String? ?? '') ?? DateTime.now();
      final messages = [
        for (final m in state.messages)
          if (ids.contains(m.id) && m.readAt == null) m.copyWith(readAt: readAt) else m,
      ];
      state = state.copyWith(messages: messages);
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  List<String> _readMessageIds(Map<String, dynamic> data) {
    final raw = data['messageIds'];
    if (raw is List) {
      return [for (final id in raw) if (id is String) id];
    }
    final single = data['messageId'] as String? ?? data['id'] as String?;
    return single == null ? const [] : [single];
  }

  void _onTyping(Map<String, dynamic> data) {
    try {
      if (data['threadId'] != arg) return;
      final userId = data['userId'] as String?;
      if (userId == null || userId == _currentUserId) return;
      final isTyping = data['isTyping'] == true;
      // Throttle: no rebuild if nothing changed.
      if (isTyping == state.counterpartyTyping) return;
      state = state.copyWith(counterpartyTyping: isTyping);
      _typingInactivity?.cancel();
      if (isTyping) {
        _typingInactivity = Timer(typingInactivity, () {
          if (_disposed || !state.counterpartyTyping) return;
          state = state.copyWith(counterpartyTyping: false);
        });
      }
    } catch (_) {
      // Malformed socket payload — ignore.
    }
  }

  void _onChatError(Map<String, dynamic> data) {
    // The gateway reported a realtime problem — surface it subtly instead of
    // crashing. `realtimeError` is intentionally sticky so identical errors
    // don't re-show a snackbar on every reconnect.
    final message = data['message'] as String? ?? 'Realtime error';
    if (_disposed) return;
    state = state.copyWith(realtimeError: message);
  }

  /// Sends a text message. Returns true when the server acked it — on failure
  /// the optimistic bubble is kept (marked failed) and the draft is preserved,
  /// so a message is never silently lost.
  Future<bool> sendText(String text) => _send(
        SendMessageInput(content: text.trim(), type: MessageType.text),
      );

  Future<bool> sendImage(String path) => _send(
        SendMessageInput(content: '', type: MessageType.image, filePath: path),
      );

  Future<bool> sendVoice(String path) => _send(
        SendMessageInput(content: '', type: MessageType.voice, filePath: path),
      );

  Future<bool> _send(SendMessageInput input) async {
    if (state.sending) return false;
    // Optimistic: render the message immediately as pending (WhatsApp-style
    // instant feedback), then reconcile with the server echo.
    final optimistic = ChatMessage(
      id: _optimisticId(),
      threadId: arg,
      senderId: _currentUserId,
      type: input.type,
      content: input.content,
      fileUrl: input.filePath,
      sentAt: DateTime.now(),
      pending: true,
    );
    state = state.copyWith(
      messages: [...state.messages, optimistic],
      sending: true,
    );
    try {
      final sent = await ref.read(chatRepositoryProvider).send(arg, input);
      if (_disposed) return true;
      _replaceOptimistic(optimistic.id, sent);
      stopTyping();
      return true;
    } catch (error) {
      if (_disposed) return false;
      _markFailed(optimistic.id);
      state = state.copyWith(sending: false, error: error.toString());
      return false;
    }
  }

  /// Swaps the pending message for the server echo. If the echo already
  /// arrived via `message:created` first, this is a no-op (dedup by id).
  void _replaceOptimistic(String localId, ChatMessage server) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == localId);
    if (index != -1) {
      messages[index] = server;
    } else if (!messages.any((m) => m.id == server.id)) {
      messages.add(server);
    }
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    state = state.copyWith(messages: messages, sending: false);
  }

  void _markFailed(String localId) {
    final messages = [
      for (final m in state.messages)
        if (m.id == localId) m.copyWith(pending: false, failed: true) else m,
    ];
    state = state.copyWith(messages: messages);
  }

  /// Re-sends a message whose first attempt failed. The failed bubble keeps its
  /// content, so retrying never loses it.
  Future<void> retry(ChatMessage failed) async {
    if (state.sending) return;
    final messages = [for (final m in state.messages) if (m.id != failed.id) m];
    state = state.copyWith(messages: messages);
    await _send(SendMessageInput(
      content: failed.content,
      type: failed.type,
      filePath: failed.fileUrl,
    ));
  }

  /// Notifies the counterparty that the current user is typing. Debounces the
  /// socket emits so a fast typer doesn't spam them.
  void notifyTyping() {
    if (_disposed) return;
    final now = DateTime.now();
    if (!_typingActive) {
      _typingActive = true;
      _emitTyping(true);
    } else if (now.difference(_lastTypingEmit) >= typingEmitInterval) {
      _emitTyping(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(typingEmitInterval, () {
      if (_typingActive) {
        _typingActive = false;
        _emitTyping(false);
      }
    });
  }

  /// Stops the typing indicator — called when the composer is cleared and when
  /// leaving the thread.
  void stopTyping() {
    _typingDebounce?.cancel();
    if (_typingActive) {
      _typingActive = false;
      _emitTyping(false);
    }
  }

  void _emitTyping(bool isTyping) {
    try {
      ref.read(socketServiceProvider).emit(
            'typing',
            {'threadId': arg, 'isTyping': isTyping},
            namespace: SocketService.chatNamespace,
          );
      _lastTypingEmit = DateTime.now();
    } catch (_) {
      // Socket not connected — the indicator is best-effort.
    }
  }

  /// Best-effort read receipt: tells the server (and the other party) the
  /// thread was opened. Never throws.
  Future<void> markRead() async {
    final unreadIds = [
      for (final m in state.messages)
        if (!m.isMine(_currentUserId) && m.readAt == null) m.id,
    ];
    try {
      ref.read(socketServiceProvider).emit(
            'message:read',
            {
              'threadId': arg,
              if (unreadIds.isNotEmpty) 'messageIds': unreadIds,
            },
            namespace: SocketService.chatNamespace,
          );
    } catch (_) {
      // Ignore — the backend may not be reachable.
    }
    try {
      await ref.read(chatRepositoryProvider).markRead(arg);
    } catch (_) {
      // Ignore — the backend may not be reachable.
    }
  }

  String _optimisticId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${_optimisticSeq++}';
}

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(
  ChatController.new,
);
