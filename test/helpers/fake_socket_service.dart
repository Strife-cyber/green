import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:green/core/realtime/socket_service.dart';

/// A [SocketService] that never opens a socket. Widget tests mount screens
/// that eagerly call `connectWhenAuthed` (e.g. the chat tab inside the role
/// shells' IndexedStack), but `flutter_dotenv` is not loaded in tests — the
/// real service would throw `NotInitializedError` and open real connections to
/// localhost. This fake satisfies the interface and keeps streams inert.
class FakeSocketService implements SocketService {
  @override
  bool isConnected([String namespace = SocketService.chatNamespace]) => false;

  @override
  Future<void> connected([String namespace = SocketService.chatNamespace]) =>
      Future<void>.value();

  @override
  void connect({required String token, String namespace = SocketService.chatNamespace}) {}

  @override
  void joinRoom(String namespace, Map<String, dynamic> data) {}

  @override
  Future<void> connectWhenAuthed(
    Ref ref, {
    String namespace = SocketService.chatNamespace,
  }) =>
      Future<void>.value();

  @override
  void disconnect([String namespace = SocketService.chatNamespace]) {}

  @override
  void disconnectAll() {}

  @override
  void emit(
    String event,
    Map<String, dynamic> data, {
    String namespace = SocketService.chatNamespace,
  }) {}

  @override
  Stream<Map<String, dynamic>> events(
    String event, {
    String namespace = SocketService.chatNamespace,
  }) =>
      const Stream<Map<String, dynamic>>.empty();
}
