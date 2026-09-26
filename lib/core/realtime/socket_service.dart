import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/auth/controllers/auth_controller.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Thin wrapper over socket.io that mirrors the backend `@nestjs/websockets`
/// gateways: **chat on the ROOT namespace**, **deliveries on `/deliveries`**.
/// Auth is sent on the handshake (JWT); events are exposed as typed streams.
///
/// Real protocol (see the backend gateway):
/// - chat:  client `join` {threadId} · `message:send` · `message:read`
///          server `message:created` · `message:read` · `chat:error`
/// - deliveries: client `join` {deliveryId} · `location:update` {lat,lng}
///          server `location:updated`
///
/// Lifecycle:
/// - [connect] / [connectWhenAuthed] open a namespace with the current JWT.
/// - A rejected handshake (e.g. the access token expired mid-session) re-reads
///   the CURRENT token from storage and reconnects with it, so realtime never
///   dies on token expiry.
/// - [disconnectAll] tears everything down on logout/session-expiry so a
///   previous user's stream can't keep flowing.
class SocketService {
  static const String chatNamespace = '';
  static const String deliveriesNamespace = '/deliveries';

  final TokenStorage _tokens;

  final Map<String, io.Socket> _sockets =
      <String, io.Socket>{};
  final Map<String, Map<String, StreamController<Map<String, dynamic>>>> _controllers =
      <String, Map<String, StreamController<Map<String, dynamic>>>>{};

  /// Rooms to (re)join per namespace, keyed by the room payload's id — so the
  /// join is re-sent automatically on every (re)connect.
  final Map<String, List<Map<String, dynamic>>> _rooms =
      <String, List<Map<String, dynamic>>>{};

  /// The JWT each namespace's socket was created with — the `connect_error`
  /// handler compares against it to detect a token change and reconnect.
  final Map<String, String> _tokensByNamespace =
      <String, String>{};

  /// Per-namespace "connected" futures — completed on the next successful
  /// handshake, errored if the handshake is rejected or the socket is torn
  /// down while pending, so screens never hang.
  final Map<String, Completer<void>> _connected =
      <String, Completer<void>>{};

  SocketService(this._tokens);

  bool isConnected([String namespace = chatNamespace]) =>
      _sockets[namespace]?.connected ?? false;

  /// Completes when the socket on [namespace] is connected. If it is already
  /// connected this returns immediately; otherwise it resolves on the next
  /// successful handshake. Errors if the handshake is rejected (expired token,
  /// server down) or the socket is torn down — catch it and retry if desired.
  Future<void> connected([String namespace = chatNamespace]) {
    if (_sockets[namespace]?.connected ?? false) {
      return Future.value();
    }
    final completer = _connected.putIfAbsent(namespace, Completer<void>.new);
    if (completer.isCompleted) {
      // Stale completer from an earlier attempt — swap in a fresh one.
      final fresh = Completer<void>();
      _connected[namespace] = fresh;
      return fresh.future;
    }
    return completer.future;
  }

  /// Connects to a gateway namespace. A missing/invalid token makes the server
  /// disconnect immediately — callers should connect with the current JWT.
  /// Prefer [connectWhenAuthed] for screens that may open before the session
  /// restore finishes.
  void connect({required String token, String namespace = chatNamespace}) {
    final existing = _sockets.remove(namespace);
    // Disposing a socket whose connection already dropped races the library's
    // internal close and throws WebSocketConnectionClosed. The async half is
    // filtered at the app boundary (main.dart); guard the sync half here.
    try {
      existing?.dispose();
    } catch (_) {
      // Already closed or mid-close — the reference is dropped either way.
    }
    // A fresh attempt owns a fresh "connected" future; anything still awaiting
    // the previous one is told so it can't hang.
    final pending = _connected[namespace];
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Socket re-created for $namespace'));
    }
    _connected[namespace] = Completer<void>();
    _tokensByNamespace[namespace] = token;

    final base = AppConfig.wsBaseUrl;
    final url = namespace.isEmpty ? base : '$base$namespace';
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNew()
          .build(),
    );
    _sockets[namespace] = socket;

    // Surface connection state so socket failures are visible (not silent),
    // and re-join rooms on every (re)connect.
    final label = namespace.isEmpty ? '/' : namespace;
    socket.on('connect', (_) {
      debugPrint('🔌 socket connected → $label');
      final c = _connected[namespace];
      if (c != null && !c.isCompleted) c.complete();
      _rejoinAll(namespace);
    });
    socket.on('connect_error', (error) {
      debugPrint('🔌 socket connect_error $label: $error');
      final c = _connected[namespace];
      if (c != null && !c.isCompleted) c.completeError(error);
      unawaited(_retryWithCurrentToken(namespace));
    });
    socket.on('disconnect', (reason) => debugPrint('🔌 socket disconnected $label: $reason'));
    socket.on('error', (error) => debugPrint('🔌 socket error $label: $error'));

    // Re-attach any listeners already registered for this namespace.
    const empty = <String, StreamController<Map<String, dynamic>>>{};
    for (final event in (_controllers[namespace] ?? empty).keys) {
      socket.on(event, (data) => _dispatch(_controllers[namespace]![event]!, data));
    }
  }

  /// Cold-start safe connect for screens that may open before the session
  /// restore finishes: waits until a user is restored, then connects with the
  /// CURRENT token from storage (never an empty one). Callers that previously
  /// did `connect(token: token ?? '')` should switch to this.
  ///
  /// Returns without connecting if the restore resolves logged-out.
  Future<void> connectWhenAuthed(Ref ref, {String namespace = chatNamespace}) async {
    var user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      // Block until the async restore resolves — screens built during the
      // `unknown` window reach this before any token exists.
      final restored = await ref.read(authControllerProvider.future);
      user = restored.user;
      if (user == null) return; // signed out — nothing to connect.
    }
    final token = await _tokens.readAccessToken() ?? '';
    connect(token: token, namespace: namespace);
  }

  /// The server rejected the handshake — usually a token that expired while
  /// the app was running. Re-read the CURRENT token from storage and reconnect
  /// with it if it changed since this socket was created; otherwise socket.io's
  /// own reconnect keeps retrying with the same token.
  Future<void> _retryWithCurrentToken(String namespace) async {
    final current = await _tokens.readAccessToken();
    if (current == null || current.isEmpty) return; // signed out — stop here.
    if (current == _tokensByNamespace[namespace]) return; // unchanged — retry is handled.
    _tokensByNamespace[namespace] = current;
    connect(token: current, namespace: namespace);
  }

  /// Joins a room (e.g. `{'threadId': …}` on chat, `{'deliveryId': …}` on
  /// deliveries) and remembers it so it is re-sent after any reconnect.
  void joinRoom(String namespace, Map<String, dynamic> data) {
    final rooms = _rooms.putIfAbsent(namespace, () => <Map<String, dynamic>>[]);
    final id = data.values.firstOrNull?.toString();
    if (!rooms.any((room) => room.values.firstOrNull?.toString() == id)) {
      rooms.add(data);
    }
    _sockets[namespace]?.emit('join', data);
  }

  void _rejoinAll(String namespace) {
    for (final room in _rooms[namespace] ?? const <Map<String, dynamic>>[]) {
      _sockets[namespace]?.emit('join', room);
    }
  }

  void disconnect([String namespace = chatNamespace]) {
    try {
      _sockets.remove(namespace)?.dispose();
    } catch (_) {
      // Socket was already closed — nothing left to tear down.
    }
    final controllers = _controllers.remove(namespace);
    controllers?.values.forEach((c) {
      if (!c.isClosed) c.close();
    });
  }

  /// Tears down every namespace socket — call on logout / session expiry so a
  /// stale user's realtime stream can't keep flowing. Rooms and tokens are
  /// forgotten so a later login starts clean.
  void disconnectAll() {
    for (final namespace in _sockets.keys.toList()) {
      disconnect(namespace);
    }
    _rooms.clear();
    _tokensByNamespace.clear();
    for (final c in _connected.values) {
      if (!c.isCompleted) c.completeError(StateError('Socket disconnected'));
    }
    _connected.clear();
  }

  /// Sends an event (e.g. `join`, `message:send`, `message:read`,
  /// `location:update`) to the given namespace.
  void emit(String event, Map<String, dynamic> data, {String namespace = chatNamespace}) {
    _sockets[namespace]?.emit(event, data);
  }

  /// Stream of payloads for a server event (e.g. `message:created`,
  /// `location:updated`) on the given namespace.
  Stream<Map<String, dynamic>> events(String event, {String namespace = chatNamespace}) {
    final byNs = _controllers.putIfAbsent(
      namespace,
      () => <String, StreamController<Map<String, dynamic>>>{},
    );
    return byNs.putIfAbsent(event, () {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      _sockets[namespace]?.on(event, (data) => _dispatch(controller, data));
      return controller;
    }).stream;
  }

  void _dispatch(StreamController<Map<String, dynamic>> controller, dynamic data) {
    if (controller.isClosed) return;
    if (data is Map) {
      controller.add(Map<String, dynamic>.from(data));
    } else if (data is List) {
      controller.add({'data': data});
    }
  }
}

final socketServiceProvider = Provider<SocketService>(
  (ref) => SocketService(ref.watch(tokenStorageProvider)),
);
