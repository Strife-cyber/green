import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket/web_socket.dart';

import 'app.dart';
import 'core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Auto-load environment overrides (.env) so AppConfig resolves staging/local
  // without any --dart-define flags. isOptional keeps desktop/web/tests safe
  // when the file isn't bundled.
  await dotenv.load(fileName: '.env', isOptional: true);
  // Warm the SharedPreferences cache so LocalStore and the locale controller
  // resolve immediately after the first frame.
  await SharedPreferences.getInstance();
  // FCM: initialize + register the background handler before runApp so pushes
  // reach the app from any state. No-ops safely when Firebase isn't available.
  await PushService.instance.init();
  runZonedGuarded(
    () => runApp(const ProviderScope(child: GreenApp())),
    _reportUnhandled,
  );
}

/// Reports unhandled errors except the one socket_io_client throws on its own
/// teardown. When the server drops a websocket, the library's internal
/// `Socket.destroy → … → IOWebSocket.close()` calls close() on an already-closed
/// transport and web_socket's IOWebSocket throws `WebSocketConnectionClosed`.
/// The throw happens inside a library-internal microtask, so no try/catch in
/// SocketService can reach it — filtering it here keeps it from surfacing as an
/// app crash. The app reconnects deliberately (SocketService.connect), so the
/// dropped socket is always replaced.
void _reportUnhandled(Object error, StackTrace stack) {
  if (error is WebSocketConnectionClosed) {
    debugPrint('🔌 socket close raced the connection drop — ignoring: $error');
    return;
  }
  // Preserve the engine's default reporting for every other error.
  PlatformDispatcher.instance.onError?.call(error, stack);
}
