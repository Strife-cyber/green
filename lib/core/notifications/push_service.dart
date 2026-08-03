import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/repositories/device_token_repository.dart';
import '../../firebase_options.dart';
import '../../l10n/l10n_ext.dart';
import '../../theme/app_colors.dart';
import '../network/media_url.dart';
import '../router/app_router.dart';

/// Background/terminated pushes are rendered by the OS tray from the
/// `notification` block the backend sends — this handler only needs to exist
/// so Android delivers the data payload and the callback slot is registered
/// before `runApp`. It deliberately does no work.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Bridges FCM to the app: initializes Firebase, registers the device token
/// with the backend, shows a foreground [MaterialBanner], and deep-links on
/// tap. A singleton with **no stored Riverpod state** — repositories, the
/// router and auth are injected by the caller, so widget tests that never run
/// `main()` stay untouched (`_fcmReady` stays false and every method no-ops).
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// Attached to `MaterialApp.router` so foreground banners can be shown from
  /// a non-widget context.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  FirebaseMessaging? _messaging;
  DeviceTokenRepository? _repo;
  bool _fcmReady = false;
  bool _listening = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _pendingData;
  String? _activeBannerMessageId;

  bool get isReady => _fcmReady;

  /// Whether a user is logged in — set by `GreenApp` on every auth change.
  /// Device tokens may only be registered while authenticated (the backend
  /// rejects unauthenticated registrations with 401), so this also triggers
  /// registration on the logged-out → logged-in transition.
  bool get isAuthenticated => _isAuthenticated;
  set isAuthenticated(bool value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    if (value) unawaited(registerToken());
  }

  /// Initializes Firebase and registers the background handler. Idempotent;
  /// called from `main()` before `runApp`. Every failure is swallowed so
  /// desktop/web/tests run with push cleanly disabled.
  Future<void> init() async {
    if (_fcmReady) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _fcmReady = true;
      debugPrint('🔔 FCM initialized');
    } catch (e) {
      _fcmReady = false;
      debugPrint('🔔 FCM init skipped (push disabled): $e');
    }
  }

  /// Called from `GreenApp.build`: stores the (live) repository and attaches
  /// the message listeners exactly once.
  void attach(DeviceTokenRepository repo) {
    _repo = repo;
    final messaging = _messaging;
    if (!_fcmReady || messaging == null || _listening) return;
    _listening = true;
    unawaited(messaging.requestPermission(alert: true, badge: true, sound: true));
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    messaging.onTokenRefresh.listen(_onTokenRefresh);
    // Cold-start tap — the payload arrives before auth restore, so it is only
    // buffered here and dispatched once the session is known (app.dart).
    messaging.getInitialMessage().then((m) {
      if (m != null) _onOpened(m);
    });
  }

  /// Registers the current FCM token with the backend (on login / restore).
  /// Never throws.
  Future<void> registerToken() async {
    final repo = _repo;
    final messaging = _messaging;
    if (!_fcmReady || messaging == null || repo == null) return;
    if (!_isAuthenticated) return; // No JWT to send — the backend would 401.
    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await repo.register(token, DevicePlatform.fcm);
    } catch (e) {
      debugPrint('🔔 FCM token registration failed: $e');
    }
  }

  /// Removes the current token from the backend. Called from `logout()` while
  /// the access token is still valid. Never throws.
  Future<void> deregisterToken() async {
    final repo = _repo;
    final messaging = _messaging;
    if (!_fcmReady || messaging == null || repo == null) return;
    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await repo.remove(token);
    } catch (e) {
      debugPrint('🔔 FCM token deregistration failed: $e');
    }
  }

  /// Invoked by the caller whenever a notification was tapped (banner tap,
  /// background open, cold start) so it can dispatch the pending deep link
  /// once auth is known.
  void Function()? onDeepLink;

  /// Returns (and clears) the buffered deep-link path for the current role,
  /// or null if there is nothing pending.
  String? pendingDeepLink(UserRole? role) {
    final data = _pendingData;
    _pendingData = null;
    return data == null ? null : resolvePath(data, role);
  }

  /// Role-aware payload → route mapping. The router's redirect already bounces
  /// a wrong-role path to that role's home, so a mismatched deep link degrades
  /// gracefully.
  static String? resolvePath(Map<String, dynamic> data, UserRole? role) {
    final orderId = data['orderId']?.toString();
    final threadId = data['threadId']?.toString();
    final receiptId = data['receiptId']?.toString();
    final deliveryId = data['deliveryId']?.toString();
    bool nonEmpty(String? s) => s != null && s.isNotEmpty;

    if (nonEmpty(threadId)) {
      return role == UserRole.admin
          ? AppRoutes.adminThread(threadId!)
          : AppRoutes.chat(threadId!);
    }
    if (nonEmpty(deliveryId) && nonEmpty(orderId)) {
      return role == UserRole.driver
          ? AppRoutes.driverDelivery(deliveryId!)
          : AppRoutes.deliveryTracking(orderId!);
    }
    if (nonEmpty(receiptId) && nonEmpty(orderId)) {
      return AppRoutes.receipt(orderId!);
    }
    if (nonEmpty(orderId)) {
      return switch (role) {
        UserRole.seller => AppRoutes.sellerOrderDetail(orderId!),
        _ => AppRoutes.orderDetail(orderId!),
      };
    }
    return role == null ? null : AppRoutes.homeFor(role);
  }

  Future<void> _onTokenRefresh(String token) async {
    final repo = _repo;
    if (!_fcmReady || repo == null || !_isAuthenticated) return;
    try {
      await repo.register(token, DevicePlatform.fcm);
    } catch (e) {
      debugPrint('🔔 FCM token refresh registration failed: $e');
    }
  }

  void _onOpened(RemoteMessage message) {
    _pendingData = message.data;
    onDeepLink?.call();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentMaterialBanner();
    _activeBannerMessageId = message.messageId;
    messenger.showMaterialBanner(_buildBanner(message));
    // Auto-dismiss after ~4 s unless a newer banner replaced this one.
    Timer(const Duration(seconds: 4), () {
      if (_activeBannerMessageId != message.messageId) return;
      scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
    });
  }

  MaterialBanner _buildBanner(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? (data['title'] as String? ?? '');
    final body = message.notification?.body ?? (data['body'] as String? ?? '');
    final icon = data['icon'] as String?;
    final messenger = scaffoldMessengerKey.currentState;
    final t = messenger?.context.t;

    return MaterialBanner(
      backgroundColor: AppColors.greenContainer.withValues(alpha: 0.35),
      leading: (icon == null || icon.isEmpty)
          ? const Icon(Icons.eco_outlined, color: AppColors.green)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                resolveMediaUrl(icon),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.eco_outlined, color: AppColors.green),
              ),
            ),
      content: InkWell(
        onTap: () {
          messenger?.hideCurrentMaterialBanner();
          _onOpened(message);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (body.isNotEmpty)
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => messenger?.hideCurrentMaterialBanner(),
          child: Text(t?.ok ?? 'OK'),
        ),
      ],
    );
  }
}
