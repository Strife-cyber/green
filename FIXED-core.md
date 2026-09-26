# FIXED-core — networking / auth / realtime / router hardening

Six verified issues from the audit were fixed. No `flutter` commands run, no commits made.

## 1. Mid-session 401 → refresh → retry (`lib/core/network/api_client.dart`)

- Added a transparent `_AuthInterceptor` (replaces the old header-only one) in front of the existing logging interceptor:
  - `onRequest` still attaches `Authorization: Bearer <token>` (unchanged behaviour, still skips the refresh endpoint).
  - `onError`: a `401` that is **not** an auth endpoint (`_isNoRefreshUri`: refresh, login, signup, otp, forgot/reset password, verify-email, resend-verification) and **not already retried** triggers a single-flight token refresh — concurrent 401s share one refresh future (`_refreshOnce`, reset on completion).
  - On success it `saveSession`s the new pair and replays the original request once via `_dio.fetch(…)` with a `__authRetried` extra flag to break the loop.
  - If the refresh token is missing/empty or the refresh is rejected, it clears the session and calls the new `onSessionExpired` callback.
- New `sessionExpiredProvider` (`NotifierProvider<SessionExpiredNotifier, int>`); `apiClientProvider` wires `onSessionExpired` to `signal()`. `createApiClient` gained an optional `onSessionExpired` param — existing callers/signatures stay valid.
- `_LoggingInterceptor` and `apiExceptionFromDio` unchanged.

## 2. Silent session death on empty refresh token (`lib/features/auth/controllers/auth_controller.dart`)

- `build()` now clears the session deterministically when the stored access token is null/empty, and in the catch path when the refresh token is null/empty — logged-out state instead of a half-restored session that redirects nowhere.
- Restore success now prefers the freshest access token on disk (the interceptor may have rotated it mid-request), so `session.accessToken` stays in sync for socket/chat consumers.

## 3. Realtime socket lifecycle (`lib/core/realtime/socket_service.dart`)

- `SocketService` now takes `TokenStorage`; `socketServiceProvider` injects it.
- `disconnectAll()` — tears down every namespace socket, clears rooms/tokens, errors pending `connected()` futures. `GreenApp` calls it the moment the session is gone (logout / session expiry / failed refresh).
- `connect_error` re-reads the **current** token from storage and reconnects only if it changed (avoids a reconnect storm while socket.io's backoff retries the same token).
- New `connected([namespace])` — async way for screens to know a socket is up: resolves immediately if connected, else resolves on the next successful handshake, errors if the handshake is rejected or torn down.
- `connect({required token, namespace})`, `joinRoom`, `emit`, `events`, `disconnect([namespace])` signatures unchanged.

## 4. Cold-start auth race (`lib/core/realtime/socket_service.dart`)

- New `connectWhenAuthed(Ref ref, {String namespace})` — awaits `authControllerProvider` until a user is restored, then connects with the current storage token (never empty); no-ops if the restore resolves logged-out. Screens opening during the `unknown` window should call this instead of `connect(token: …)`.

## 5. Email-verification gate (`lib/core/router/app_router.dart`)

- Router redirect now funnels logged-in-but-unverified users to `/verify-email`; `/verify-email` stays in the public set for logged-out access.
- A `justAuthenticated` flag (set on fresh login/signup/restore, cleared on reaching `/verify-email`) lets the verify screen's `refreshSession()` (already added by the auth work) trigger a redirect re-evaluation once verification succeeds.

## 6. Stale catalog & category providers

- `lib/data/repositories/providers.dart`: `categoriesProvider` → `FutureProvider.autoDispose` (refetches after admin category CRUD).
- `lib/features/buyer/controllers/product_list_controller.dart`: `categoryListProvider` + `productCatalogProvider` → `FutureProvider.autoDispose`.
- `lib/features/seller/controllers/seller_product_list_controller.dart`: controller → `AutoDisposeAsyncNotifier`, provider → `AsyncNotifierProvider.autoDispose`.

## API additions screens should use

- `ref.read(socketServiceProvider).connectWhenAuthed(ref, namespace: SocketService.chatNamespace)` (or `…deliveriesNamespace`) instead of `connect(token: token ?? '')`.
- `await socketService.connected(namespace)` before sending, instead of assuming connected.
- `ref.read(authControllerProvider.notifier).refreshSession()` from the verify-email screen's "I've verified — check status" affordance.
- `ref.read(sessionExpiredProvider)` only if a screen needs to react to forced logout (the app root already listens).

## Deferred / notes

- `lib/features/chat/controllers/chat_controller.dart` and `lib/features/delivery/controllers/delivery_tracking_controller.dart` still call `socket.connect(token: token ?? '')` directly (owned by other agents) — they should switch to `connectWhenAuthed`.
- `productListControllerProvider` (buyer grid) intentionally left non-`autoDispose` (pull-to-refresh + search state).
- A mid-session interceptor refresh updates storage but not the in-memory `AuthState`; the socket `connect_error` self-heal re-reads storage so realtime stays correct.
