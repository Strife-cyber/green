import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Thin wrapper over socket.io that mirrors the backend `@nestjs/websockets`
/// gateways (chat + delivery). Auth is sent on the handshake; events are
/// exposed as typed streams per event name.
class SocketService {
  io.Socket? _socket;
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String token, String? baseUrl}) {
    disconnect();
    _socket = io.io(
      baseUrl ?? 'http://10.0.2.2:8080',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNew()
          .build(),
    );
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  void emit(String event, [Map<String, dynamic>? data]) {
    if (data == null) {
      _socket?.emit(event);
    } else {
      _socket?.emit(event, data);
    }
  }

  /// Listens for [event] (e.g. `chat.messageCreated`, `delivery.locationUpdated`).
  Stream<Map<String, dynamic>> events(String event) {
    return _controllers.putIfAbsent(event, () {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      _socket?.on(event, (data) {
        if (data is Map) {
          controller.add(Map<String, dynamic>.from(data));
        } else if (data is List) {
          controller.add({'data': data});
        }
      });
      return controller;
    }).stream;
  }
}

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());
