import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

/// Thin wrapper over socket.io that mirrors the backend `@nestjs/websockets`
/// gateways: **chat on the ROOT namespace**, **deliveries on `/deliveries`**.
/// Auth is sent on the handshake (JWT); events are exposed as typed streams.
///
/// Real protocol (see the backend gateway):
/// - chat:  client `join` {threadId} · `message:send` · `message:read`
///          server `message:created` · `message:read` · `chat:error`
/// - deliveries: client `join` {deliveryId} · `location:update` {lat,lng}
///          server `location:updated`
class SocketService {
  static const String chatNamespace = '';
  static const String deliveriesNamespace = '/deliveries';

  final Map<String, io.Socket> _sockets =
      <String, io.Socket>{};
  final Map<String, Map<String, StreamController<Map<String, dynamic>>>> _controllers =
      <String, Map<String, StreamController<Map<String, dynamic>>>>{};

  /// Rooms to (re)join per namespace, keyed by the room payload's id — so the
  /// join is re-sent automatically on every (re)connect.
  final Map<String, List<Map<String, dynamic>>> _rooms =
      <String, List<Map<String, dynamic>>>{};

  bool isConnected([String namespace = chatNamespace]) =>
      _sockets[namespace]?.connected ?? false;

  /// Connects to a gateway namespace. A missing/invalid token makes the server
  /// disconnect immediately — callers should connect with the current JWT.
  void connect({required String token, String namespace = chatNamespace}) {
    final existing = _sockets.remove(namespace);
    existing?.dispose();
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
      _rejoinAll(namespace);
    });
    socket.on('connect_error', (error) => debugPrint('🔌 socket connect_error $label: $error'));
    socket.on('disconnect', (reason) => debugPrint('🔌 socket disconnected $label: $reason'));
    socket.on('error', (error) => debugPrint('🔌 socket error $label: $error'));

    // Re-attach any listeners already registered for this namespace.
    const empty = <String, StreamController<Map<String, dynamic>>>{};
    for (final event in (_controllers[namespace] ?? empty).keys) {
      socket.on(event, (data) => _dispatch(_controllers[namespace]![event]!, data));
    }
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
    _sockets.remove(namespace)?.dispose();
    final controllers = _controllers.remove(namespace);
    controllers?.values.forEach((c) => c.close());
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

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());
