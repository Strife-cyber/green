# GREENISH — Flutter Frontend Implementation Plan

**Version:** 1.0 (draft)
**Date:** 2026-08-02
**Stack:** Flutter 3.44 / Dart 3.12 · Riverpod (state) · go_router (routing) · Dio (HTTP) · socket.io client (realtime)
**Source of truth:** [REQUIREMENTS.md](../../docs/REQUIREMENTS.md) (52 rows) · [Backend Plan](../green-backend/docs/IMPLEMENTATION_PLAN.md) (NestJS, phases 0–5) · [DATABASE_DESIGN.md](../../docs/DATABASE_DESIGN.md) (23 models / 16 enums)

> **How this is used:** the backend is being built in parallel and is **not yet operational**. The frontend is developed against **mock repositories** behind interfaces. When the backend ships, we flip a flag and the same screens/controllers talk to the real API. The Swagger spec then drives the repository implementations (see §10 Hand-off checklist).

---

## 1. Current State (already done in `green/`)

| Area | Status |
|---|---|
| Theme | ✅ `lib/theme/` — `AppColors` (logo-derived cream/green/orange), `AppTheme` light+dark, Material 3 |
| Typeface | ✅ Quicksand (SIL OFL), static weights 400–700 bundled in `assets/fonts/` |
| Native splash | ✅ `flutter_native_splash` — cream `#EAD7BD` + logo (no white flash) |
| In-app splash | ✅ `animated_splash_themes` `expand` style → home |
| Logo asset | ✅ `assets/logo.png` (true PNG, 1024×1024), blends on cream |

**Not started:** everything below. The legacy `flutter_app/` + `backend/` in the repo root is the old product being replaced — review its screens for UX reference only; **do not port its code** (no RBAC, in-memory cart, non-transactional orders).

---

## 2. Frontend Decisions (D-FE)

| # | Decision | Choice |
|---|---|---|
| D-FE1 | State management | **Riverpod** — `Notifier`/`AsyncNotifier` are the "controllers". No codegen for v1 (manual providers); can add `riverpod_generator` later if boilerplate grows. |
| D-FE2 | API layer | **Hand-written Dio repository classes**; Swagger is the reference doc, not a codegen input. |
| D-FE3 | Backend readiness | **Mock-first**: every repository has an interface + `Mock…Repository` (now) + `Api…Repository` (later). One provider switch: `useMocks`. |
| D-FE4 | Routing | **go_router** with auth + role redirects (`/buyer`, `/seller`, `/admin`, `/driver` shells). |
| D-FE5 | Cart | Client-side only (per DB design §1 note). Persisted locally; materialises into an order at checkout. |
| D-FE6 | Money | All amounts are **`int` FCFA (XAF)** in the UI; parse backend `Decimal`-as-string centrally. No floats. |
| D-FE7 | Realtime | **socket_io_client** (matches NestJS `@nestjs/websockets`). Chat + delivery rooms, JWT on handshake. |
| D-FE8 | Tokens | `flutter_secure_storage` for tokens; `shared_preferences` for cart/prefs cache. |

---

## 3. Architecture

Three layers, one direction of dependency. **Screens never touch Dio or the network** — they read controllers (Riverpod), which call repositories (interfaces), which are backed by mocks or Dio.

```
Presentation  →  features/*/screens + shared/widgets   (pure UI, reads controllers)
Application   →  features/*/controllers                (Riverpod Notifiers — state + orchestration)
Data          →  data/repositories + models            (interfaces → Mock | Api via Dio)
        Core →  core/network · storage · router · realtime · utils   (no feature logic)
```

### Folder structure

```
lib/
├── main.dart                     # bootstrap: ProviderScope, init storage, runApp
├── app.dart                      # MaterialApp.router, theme wiring
├── theme/                        # ✅ existing
├── core/
│   ├── network/
│   │   ├── api_client.dart       # Dio + base URL + auth/retry interceptors
│   │   ├── api_exception.dart    # parses { data, meta, error } envelope → typed errors
│   │   └── endpoints.dart        # every endpoint as a constant (mirrors Swagger)
│   ├── storage/
│   │   ├── token_storage.dart    # secure tokens (write/read/clear)
│   │   └── local_store.dart      # prefs: cart cache, onboarding, flags
│   ├── router/
│   │   ├── app_router.dart       # GoRouter + redirects
│   │   └── routes.dart           # route names/constants
│   ├── realtime/
│   │   └── socket_service.dart   # socket.io connect + rooms + event streams
│   └── utils/
│       ├── money.dart            # int FCFA, Decimal-string parser, formatting
│       ├── formatters.dart       # dates, quantities
│       ├── validators.dart       # email, phone, password strength (AUTH-01)
│       └── cameroon.dart         # 10 regions list, phone prefix handling
├── data/
│   ├── models/                   # one file per domain model (+ enums) — §5
│   ├── repositories/             # abstract class per backend module — §6
│   │   ├── auth_repository.dart
│   │   ├── product_repository.dart
│   │   ├── order_repository.dart
│   │   ├── category_repository.dart
│   │   ├── wallet_repository.dart
│   │   ├── delivery_repository.dart
│   │   ├── chat_repository.dart
│   │   ├── … (one per module)
│   ├── api/                      # Api…Repository implements (Dio) — written at hand-off
│   └── mock/                     # Mock…Repository implements + seeded data
│       └── mock_data.dart
├── features/                     # one per domain (mirrors backend modules)
│   ├── auth/        controllers/ screens/ widgets/
│   ├── buyer/       product catalog, cart, checkout, orders, wishlist, addresses
│   ├── seller/      products, orders, dashboard, analytics
│   ├── wallet/      balance, transactions, payments, withdrawals
│   ├── delivery/    driver flow, live tracking
│   ├── chat/        threads, messages, voice
│   ├── admin/       stats, approvals, wallets, withdrawals, tickets, reports, deliveries
│   ├── notifications/
│   ├── receipts/
│   └── settings/    profile, support tickets
└── shared/
    └── widgets/                 # reusable widgets — §7
```

> YAGNI note: the tree above is the **target**; each phase adds only the folders it needs. Phase 0 ships `core/ + data/(auth,user) + features/auth`.

### Data flow (mock → API swap)

```
Screens ──ref──▶ controllers (AsyncNotifier) ──await──▶ RepoInterface
                                                            │
                          ┌─────────────────────────────────┤
                          ▼                                 ▼
              Mock…Repository (now)                Api…Repository (Dio)
                                                    (written from Swagger, §10)
                          └───────── both provide identical models ─────────┘
```

The provider wiring lives in `features/<domain>/controllers/providers.dart` and reads `Ref.read(useMocksProvider)`.

---

## 4. Core Infrastructure

### 4.1 Network — `core/network/`

- **`ApiClient`** — Dio instance with base URL from `--dart-define=API_BASE_URL`; interceptor order:
  1. **Auth interceptor** — attach `Authorization: Bearer <token>`; on `401` → attempt refresh once → retry → else force logout.
  2. **Envelope interceptor** — unwrap `{ data, meta, error }` (backend §2.3); map HTTP status + `error` to typed `ApiException` (`ApiException.network/unauthorized/forbidden/notFound/conflict/validation`).
  3. **Logging interceptor** (debug only).
- **`Endpoints`** — one constant per route, grouped by module. This file is the frontend mirror of the Swagger and is the main thing updated at hand-off.

### 4.2 Storage — `core/storage/`

- `TokenStorage` (secure) — access/refresh tokens.
- `LocalStore` (prefs) — cart snapshot, last role, onboarding seen.

### 4.3 Router — `core/router/`

- `GoRouter` with a `redirect` that reads `AuthController`. Rules:
  - No session → allow only `/login`, `/signup`, `/forgot-password`, `/verify-email`.
  - Buyer → `/buyer` shell; Seller → `/seller` shell (+ **pending banner** if `approvalStatus != approved`, AUTH-07); Driver → `/driver`; Admin → `/admin` (AUTH-06, never visible to other roles).
  - Unverified email (D7) → allow browse (`/buyer`) but gate checkout.
- Route tree in §8.

### 4.4 Realtime — `core/realtime/`

- `SocketService` wraps `socket_io_client`; connect after login with JWT; exposes typed streams:
  - `chat.messageCreated(threadId)`, `chat.read(threadId)` (CHAT-04)
  - `delivery.locationUpdated(deliveryId)` (DRV-03)
- Controllers subscribe via `StreamBuilder`-style listeners and update `AsyncValue` state. Backend event contracts (§9.3 of backend plan): `chat.messageCreated`, `chat.read`, `delivery.locationUpdated`.

---

## 5. Models (`data/models/`) — mirror of the DB / Swagger DTOs

Hand-written Dart classes (`fromJson`/`toJson`), one per entity, enums as Dart enums. Naming avoids Flutter collisions (`Transaction`→`WalletTransaction`, `Notification`→`AppNotification`, `ReportedUser`→`Report`).

| DB model | Dart model | Feature owner |
|---|---|---|
| users | `User`, `AuthSession`, `AuthState` | auth |
| seller_profiles | `SellerProfile` | auth / seller / admin |
| categories | `Category` | buyer |
| products | `Product` | buyer / seller |
| addresses | `Address` | buyer (saved addresses) |
| orders | `Order`, `OrderItem`, `OrderStatusHistory` | buyer / seller / admin |
| wallets | `Wallet` | wallet |
| transactions | `WalletTransaction` | wallet |
| withdrawals | `Withdrawal` | wallet / admin |
| platform_config | `PlatformConfig` | core (commission %, min withdrawal, receipt prefix) |
| receipts | `Receipt`, `ReceiptCopy` | receipts |
| deliveries | `Delivery` | delivery / driver |
| chat_threads / chat_messages | `ChatThread`, `ChatMessage` | chat |
| wishlist_items | `WishlistItem` | buyer |
| ratings_reviews | `RatingReview` | buyer / seller |
| notifications / device_tokens | `AppNotification`, `DeviceToken` | notifications |
| support_tickets | `SupportTicket` | settings / admin |
| reported_users | `Report` | admin |

**Enums (16):** `UserRole`, `SellerApprovalStatus`, `OrderStatus`, `PaymentStatus`, `TransactionType`, `TransactionStatus`, `WithdrawalChannel`, `WithdrawalStatus`, `ReceiptStatus`, `NotificationType`, `MessageType`, `DevicePlatform`, `TicketStatus`, `ReportTargetType`, `ReportStatus`, `ReceiptCopyRole` — mirror backend names 1:1 (they will match the Swagger enum values).

**Money:** every amount is `int` FCFA. A single `parseMoney(String?)` in `core/utils/money.dart` converts Prisma `Decimal`-as-string (`"2500.00"`) → `2500`; `formatMoney(int)` → `2 500 FCFA` via `intl`.

---

## 6. Repositories (`data/repositories/`) — mock-first

One abstract class per backend module, with the endpoints from the backend plan baked into the method signatures. **This file set is the contract** — screens are built against it today with mocks, and the `Api…` implementations just fill in Dio calls later.

```dart
abstract class ProductRepository {
  Future<List<Product>> list({String? search, int? categoryId, int page, int pageSize});
  Future<Product> get(String id);
  Future<Product> create(CreateProductInput input);   // multipart: image
  Future<Product> update(String id, UpdateProductInput input);
  Future<void> delete(String id);
}
```

| Module | Key methods (from backend endpoints) |
|---|---|
| `AuthRepository` | `login`, `signup`, `refresh`, `logout`, `forgotPassword`, `resetPassword`, `me`, `verifyEmail` |
| `UserRepository` | `getProfile`, `updateProfile`, `updateLocation` |
| `SellerProfileRepository` | `submit` (signup), `me`, `status` |
| `CategoryRepository` | `list` |
| `ProductRepository` | `list`, `get`, `create`, `update`, `delete` (+ upload) |
| `AddressRepository` | `list`, `create`, `update`, `delete`, `setDefault` |
| `OrderRepository` | `create` (checkout), `buyerOrders`, `sellerOrders`, `get`, `updateStatus` (confirm/cancel/ship), `statusHistory` |
| `WishlistRepository` | `list`, `toggle` |
| `RatingRepository` | `create` (one per delivered order), `sellerSummary` |
| `WalletRepository` | `me`, `transactions` |
| `PaymentRepository` | `initiateMomo`, `initiateOrange`, `status` |
| `WithdrawalRepository` | `request`, `myRequests` |
| `DeliveryRepository` | `assign`, `driverOrders`, `get`, `pickup`, `deliver` |
| `ChatRepository` | `threads`, `messages`, `sendMessage` (text/image/voice), `markRead` |
| `NotificationRepository` | `list`, `markRead` |
| `ReceiptRepository` | `getForOrder`, `downloadPdf` |
| `SupportRepository` | `create`, `myTickets` |
| `ReportRepository` | `submit`, `reasons` |
| `AdminRepository` | `stats`, `pendingSellers`, `approveSeller`, `rejectSeller`, `pendingWithdrawals`, `processWithdrawal`, `rejectWithdrawal`, `activeDeliveries`, `allWalletBalances`, `tickets`, `ticketAction`, `reports`, `reportAction`, `readChatThread`, `createDriver` |

---

## 7. Controllers (Riverpod "controllers") & Reusable Widgets

### 7.1 Controllers (`features/*/controllers/`)

| Controller | Kind | Responsibility |
|---|---|---|
| `AuthController` | `AsyncNotifier<AuthState>` | session, login/signup/logout/refresh, restore on start, role |
| `ProductListController` | `AsyncNotifier<List<Product>>` | feed + search + category filter + pagination (BUY-01/02/03) |
| `ProductDetailController` | `AsyncNotifier<Product>` | BUY-04 |
| `CartController` | `Notifier<Cart>` | add/adjust/remove/clear, **persisted** (BUY-06) |
| `WishlistController` | `Notifier<Set<String>>` | toggle (BUY-05) |
| `AddressController` | `AsyncNotifier<List<Address>>` | saved addresses (BUY-08) |
| `CheckoutController` | `Notifier<CheckoutState>` | submit order, pay-now hook (BUY-07) |
| `BuyerOrderListController` | `AsyncNotifier<List<Order>>` | history + actions (BUY-09/10) |
| `SellerProductListController` | `AsyncNotifier<List<Product>>` | CRUD (SELL-01) |
| `SellerOrderListController` | `AsyncNotifier<List<Order>>` | confirm/cancel/ship (SELL-02) |
| `SellerDashboardController` | `AsyncNotifier<SellerAnalytics>` | weekly revenue, best sellers, customers, monthly chart (SELL-03/04/05/07) |
| `WalletController` | `AsyncNotifier<Wallet>` | balance + escrow (PAY-03) |
| `LedgerController` | `AsyncNotifier<List<WalletTransaction>>` | transaction history (PAY-07) |
| `PaymentController` | `Notifier<PaymentState>` | initiate MoMo/OM, poll status (PAY-01/02/08) |
| `WithdrawalController` | `AsyncNotifier<List<Withdrawal>>` | request + list (PAY-05) |
| `DriverDeliveryListController` | `AsyncNotifier<List<Delivery>>` | assigned orders (DRV-02) |
| `DeliveryTrackingController` | `Notifier<DeliveryState>` | **realtime** location + status (DRV-03, DEL-03) |
| `ChatThreadListController` | `AsyncNotifier<List<ChatThread>>` | threads (CHAT-01) |
| `ChatController` | `Notifier<ChatState>` | messages + send + **realtime** subscribe + read (CHAT-02/03/04) |
| `NotificationController` | `AsyncNotifier<List<AppNotification>>` | in-app centre (NOT-01..06) |
| `ReceiptController` | `AsyncNotifier<Receipt>` | view + download (REC-01/04) |
| `SupportController` | `AsyncNotifier<List<SupportTicket>>` | enquiry desk (ADM-10) |
| `AdminStatsController` | `AsyncNotifier<AdminStats>` | users/sellers/revenue/commission (ADM-01..04) |
| `AdminWalletController` | `AsyncNotifier<AdminWalletsView>` | balances + withdrawals processing (ADM-05/06) |
| `AdminApprovalController` | `AsyncNotifier<List<SellerProfile>>` | approve/reject (ADM-11) |
| `AdminDeliveryController` | `AsyncNotifier<List<Delivery>>` | live deliveries (ADM-08) |
| `AdminTicketController`, `AdminReportController`, `AdminChatController` | `AsyncNotifier` | ADM-09/07/12 |

### 7.2 Reusable widgets (`shared/widgets/`)

| Widget | Used by | Purpose |
|---|---|---|
| `AsyncView<T>` | **every screen** | renders `AsyncValue` → loading spinner / `ErrorView` + retry / content (single source of truth for loading/error UX) |
| `ErrorView`, `EmptyState` | all lists | consistent error & empty states |
| `ProductCard` / `ProductGrid` | home, search, seller | image, category tag, price/kg, seller name |
| `CategoryChips` | home | BUY-03 filter chips |
| `DebouncedSearchBar` | home, admin | BUY-02 |
| `QuantityStepper` | detail, cart | BUY-04/06 |
| `AmountText` | everywhere | `int` → `2 500 FCFA` (D-FE6) |
| `StatusBadge` | orders, receipts | colour-coded `OrderStatus` / `PaymentStatus` (DEL-01) |
| `SellerCard` | product detail | farm info + rating (BUY-04) |
| `UserAvatar` | chat, comments | initials fallback |
| `ImageNetwork` | products, chat | placeholder + error fallback |
| `PhotoPicker` | seller CRUD, profile, chat | image_picker + upload via repo |
| `OrderTimeline` | order detail | status progress `pending→confirmed→shipped→delivered` |
| `RoleShell` | buyer/seller/admin/driver | bottom nav / drawer per role (AUTH-06) |
| `MapView` | delivery tracking | `flutter_map` wrapper |
| `ChatBubble`, `MessageComposer`, `VoiceNotePlayer` | chat | text/image/voice (CHAT-02) |
| `StatCard`, `LineChartCard` | dashboards | seller + admin analytics |
| `PasswordStrengthBar` | signup | AUTH-01 strength meter |
| `CurrencyField`, `PhoneField`, `RegionDropdown` | forms | validated inputs |

---

## 8. Role-Based Navigation

```
/splash                        (native splash → in-app splash → auth gate)
/login · /signup · /forgot-password · /verify-email
/buyer/home  /buyer/search  /buyer/product/:id  /buyer/cart  /buyer/checkout
             /buyer/orders  /buyer/orders/:id  /buyer/wishlist  /buyer/addresses
             /buyer/chat/:threadId  /buyer/tracking/:orderId  /buyer/receipt/:orderId
/seller/home  /seller/products  /seller/products/new  /seller/products/:id/edit
             /seller/orders  /seller/orders/:id  /seller/dashboard  /seller/wallet
             /seller/chat/:threadId  /seller/profile   (+ pending-approval banner)
/driver/home  /driver/deliveries/:id  /driver/chat/:threadId  /driver/profile
/admin  (stats, sellers, wallets, withdrawals, deliveries, tickets, reports, chat)
```

Redirect logic (go_router `redirect`): auth gate + role shell selection. **Server RBAC is the real gate** — the client route split is UX only (backend §2.3 / §0 security fixes).

---

## 9. Phased Plan (mirrors backend; mock-first until API live)

> Each phase = build screens + controllers against `Mock…Repository`, then the `Api…Repository` at hand-off. Exit criteria assume mocks + widget tests green.

### Phase 0 — Foundation & Auth ✅
- [x] Add deps: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `shared_preferences`, `intl`, `mocktail` (dev)
- [x] `core/network` (ApiClient + interceptors + envelope parsing), `core/storage`, `core/router`, `core/utils` (money, validators, cameroon regions)
- [x] Models: `User`, `AuthSession`, `SellerProfile`; enums `UserRole`, `SellerApprovalStatus`
- [x] `AuthRepository` interface + `MockAuthRepository`
- [x] Auth feature: login, signup (buyer + seller with farm fields + license), forgot/reset, verify-email placeholder
- [x] `AuthController` (persist/restore session, AUTH-08), `PasswordStrengthBar`, role redirect
- [x] App bootstrap: `main.dart` ProviderScope + `app.dart` router + theme
- [x] **Exit:** splash → login → role home; session survives restart; seller sees pending banner (AUTH-07)

### Phase 1 ✅ — Shopping core (MVP)
- [x] Models: `Category`, `Product`, `Address`, `Order`, `OrderItem`, `OrderStatusHistory`
- [x] Repos: `Category`, `Product`, `Address` (basic), `Order` + mocks
- [x] Buyer: home feed (grid + chips + search), product detail (qty selector), **persisted cart** (D-FE5), checkout (choose/save address), order history + actions, wishlist toggle
- [x] Seller: product CRUD (+ `PhotoPicker` upload), order management (confirm/cancel/ship), `StatusBadge`, `OrderTimeline`
- [x] Admin: stats dashboard, pending-seller approval list
- [x] Widgets: `AsyncView`, `ProductCard`, `CategoryChips`, `QuantityStepper`, `AmountText`, `StatusBadge`, `EmptyState`, `ErrorView`, `RoleShell`
- [x] Controllers: §7 buyer/seller/admin core set
- [x] **Exit:** full browse→cart→checkout→history with mocks; seller CRUD + order actions; admin approval

### Phase 2 ✅ — Payments, Wallet & Escrow
- [x] Models: `Wallet`, `WalletTransaction`, `Withdrawal`, `PlatformConfig`; money enums
- [x] Repos: `Wallet`, `Payment`, `Withdrawal` + mocks (providers stubbed per backend §5.1)
- [x] Wallet feature: balance + escrow view, ledger screen (`AmountText`, signed +/−), withdrawals (min 2000 FCFA, MoMo/Orange channels)
- [x] Payment: checkout payment sheet (MTN MoMo / Orange Money), status polling, confirmation (PAY-01/02/08)
- [x] Commission display (5% subtotal) on order/receipt once `PlatformConfig` available
- [x] **Exit:** mock pay → escrow held; deliver → balance released minus commission; ledger + withdrawal request flow

### Phase 3 ✅ — Logistics (driver + live tracking)
- [x] Models: `Delivery`; `RoleShell` driver variant; admin "create driver" (D6)
- [x] Repos: `Delivery` + mock; `SocketService` (JWT handshake)
- [x] Driver: assigned deliveries, pickup → deliver actions (DRV-02/04)
- [x] Buyer/seller: live tracking screen — `MapView` (flutter_map) + `DeliveryTrackingController` listening to `delivery.locationUpdated` (DEL-03)
- [x] Delivery fee shown at checkout + receipt (D5)
- [x] Deps added: `socket_io_client`, `flutter_map`, `latlong2`, `geolocator`, `permission_handler`
- [x] **Exit:** driver broadcasts position (mock + socket), buyer sees it live, deliver triggers order `delivered`

### Phase 4 ✅ — Engagement (wishlist, ratings, addresses, chat)
- [x] Models: `WishlistItem`, `RatingReview`, `ChatThread`, `ChatMessage`; `MessageType`
- [x] Repos: `Wishlist`, `Rating`, `Chat` + mocks; address full CRUD
- [x] Wishlist screen + toggle (BUY-05); ratings/reviews after delivered order, one per order (BUY-11)
- [x] **Chat** (CHAT-01..04): threads list, message screen with text/image/voice, realtime subscribe (`chat.messageCreated`), read receipts; threads appear from the order (backend auto-creates at checkout)
- [x] Admin read-only thread view (ADM-12)
- [x] Voice: `record` + `audioplayers`; image via `PhotoPicker`
- [x] **Exit:** buyer↔seller chat in realtime on an order; rating recorded; addresses reusable at checkout

### Phase 5 ✅ — Ops & Analytics
- [x] Models: `Receipt`, `ReceiptCopy`, `SupportTicket`, `Report`, `AppNotification`, `DeviceToken`; remaining enums
- [x] Repos: `Receipt`, `Support`, `Report`, `Notification`, `Admin` (full) + mocks
- [x] Smart receipt view + PDF download (REC-01/04); three copies concept surfaced per role
- [x] Seller analytics dashboard: weekly revenue, best sellers, customer count, **monthly line chart** (`fl_chart`) (SELL-03..07)
- [x] Admin extended: commission earned, wallet balances + escrow pool, active deliveries, tickets + action, reports + action, receipts (ADM-04..08/13)
- [x] Support enquiry desk + tickets (ADM-09/10); report-a-user in chat/profile/order (D8)
- [x] Notification centre (NOT-01..06); FCM later (`firebase_messaging`)
- [x] **Exit:** full requirement coverage, mocks still enabled where API pending

---

## 9b. Addendum — Seller Identity Verification (AUTH-09 / SELL-10)

> Added 2026-08-02. Sellers now verify identity at sign-up; admins approve it.
> Implementation follows the feature-agent integration so it doesn't conflict
> with in-flight work.

- [ ] `SellerProfile` model: add `farm_description`, `farm_latitude`/`farm_longitude` (farm location), `national_id_url`, `selfie_url`
- [ ] Seller sign-up screen: **national ID card upload** + **selfie of seller or market space** (`PhotoPicker`), plus farm description + farm location fields
- [ ] `SignupInput` + mock: carry the new fields; seller stays `PENDING`
- [ ] Admin approval screen: show the farm description, farm location, categories, national ID and selfie for review before Approve/Reject (ADM-11)
- [ ] Seller profile screen: view/update farm description, location, categories, re-upload ID/selfie (SELL-10)

---

## 9c. Addendum — Trust & Security checklist (AUTH-10, PAY-10, DEL-07, ADM-14/15)

> Added 2026-08-02 (user security checklist). Status: ✅ exists / 🔜 in-flight / ⏳ pending.

| # | Feature | Req(s) | Status | Notes |
|---|---|---|---|---|
| 1 | **OTP verification** | AUTH-10 | ✅ | "Log in with a code" flow; demo code `123456`; real OTP via email/phone at hand-off |
| 2 | **Seller verification + admin approval** | AUTH-09, AUTH-07, ADM-11 | ✅ | ID + selfie + farm description at signup; admin reviews them before Approve/Reject |
| 3 | **Admin roles** | ADM-14, D9 | ⏳ | Multiple admins now; sub-role gating once RBAC is server-side (backend) |
| 4 | **Transaction records** | PAY-07 | ✅ | `WalletTransaction` + ledger screen + mock ledger |
| 5 | **Wallet protection** | PAY-10 | ✅ | Wallet PIN (salted SHA-256 in secure storage); gated payment/withdrawal; moves server-side at hand-off |
| 6 | **Delivery confirmation code** | DEL-07 | ✅ | 6-digit per-order code; driver must enter it to mark delivered; buyer sees it on tracking |
| 7 | **Reporting system** | D8, ADM-07 | ✅ | Report dialog (profile/chat/order) + admin review queue |
| 8 | **Activity logs** | ADM-15 | ✅ | Admin activity-log view over mock audit events |
| 9 | **Encrypted data storage** | NFR | ✅ | Tokens + wallet PIN stored encrypted/hashed; remaining cached PII at hand-off |
| 10 | **Backups** | NFR | ⏳ | Backend/infra concern (DB schedule + restore) — not frontend code |

---

## 9d. Addendum — BraidsBook shell & l10n standards (2026-08-02)

Applied the page/nav standards from the reference app (`braidsbook_mobile`):

- **Home shells**: role homes are a single `Scaffold` (`AppShell`) over `IndexedStack` of self-contained tab pages + a **floating pill `CustomBottomNavBar`** (selected item expands with its label, badges, haptic), anchored to the bottom. No shell AppBar → no double headers. Tab index persisted in prefs; `PopScope` back → first tab → exit. Per-role tab providers in `lib/core/router/nav_providers.dart`.
- **Bottom bar = max 4 items** (buyer: Home/Cart/Orders/Profile · seller: Dashboard/Products/Orders/Profile · driver: Deliveries/Chat/Profile · admin: Overview/Sellers/Withdrawals/Profile). Anything else goes into **`QuickActionsSection`** card tiles on the first tab (search, wallet, tickets, reports, activity, new driver, support…), never more than 4 in one bar.
- **l10n (slang)**: `slang.yaml` + `lib/l10n/app_{en,fr}.arb` → `dart run slang` → `lib/l10n/generated/strings.g.dart`. Access via `context.t` (`l10n_ext.dart`); app root wrapped in `TranslationProvider`; `MaterialApp.supportedLocales` = `L10n.flutterLocales`; locale persisted by `core/i18n/locale_controller.dart`; `LanguageSelector` widget in settings. New strings: add to both `.arb`, run `dart run slang`.
- **Remaining**: most screen-level strings are still hardcoded English — migrate key-by-key to `context.t` as screens are touched.

---

## 10. Swagger Hand-off Checklist (when the backend is live)

Given the Swagger JSON/yml, in order:

1. **Verify envelope** — confirm `{ data, meta, error }` shape and error codes match `ApiException`.
2. **Auth contract** — bearer header name, refresh endpoint/expiry, `401` behaviour.
3. **Endpoints** — diff `core/network/endpoints.dart` against Swagger paths/methods; add missing.
4. **Models** — diff field names/types against DTOs (`@ApiProperty`); fix `fromJson`.
5. **Write `Api…Repository`** per module (Dio calls, multipart uploads, pagination params).
6. **Realtime** — confirm socket namespaces, rooms (`chat/{threadId}`, `delivery/{deliveryId}`), and event DTOs from the `x-websocket` panel; align `SocketService`.
7. **Flip flag** — `useMocksProvider = false` per module; delete `Mock…Repository` for shipped modules.
8. **Polish** — error messages from `error` field, retry/idempotency for checkout + payments.

---

## 11. Dependencies (kept light; added per phase)

| Package | Phase | Why |
|---|---|---|
| `flutter_riverpod` | 0 | state (controllers) |
| `go_router` | 0 | role-based routing |
| `dio` | 0 | HTTP + interceptors |
| `flutter_secure_storage` | 0 | tokens |
| `shared_preferences` | 0 | cart/prefs cache |
| `intl` | 0 | FCFA + date formatting |
| `image_picker` | 1 | product/avatar photos |
| `socket_io_client` | 3 | realtime chat + delivery |
| `flutter_map` + `latlong2` | 3 | offline-map tracking (no API key) |
| `geolocator` + `permission_handler` | 3 | driver location |
| `record` + `audioplayers` | 4 | voice notes |
| `fl_chart` | 5 | analytics charts |
| `firebase_messaging` | 5 | push (FCM) |
| `mocktail` (dev) | 0 | controller/widget tests |

---

## 12. Testing Strategy

- **Unit** — `core/utils` (money parser/formatter, validators, region list); state-machine helpers for order status.
- **Controller tests** — Riverpod `ProviderContainer` + `Mock…Repository` (mocktail): cart add/remove/persist, checkout submit, auth restore, escrow display math.
- **Widget tests** — critical flows with mocked repos: splash→login→home, browse→cart→checkout, seller order status change, admin approval (mirrors backend NFR "Flutter widget tests for critical flows").
- **Realtime** — `SocketService` tested against a fake client; `ChatController`/`DeliveryTrackingController` driven by injected streams.

---

## 13. Open Items / What We Need From Swagger

- Exact DTO field names/casing, pagination meta shape (`page`, `pageSize`, `total`?).
- Upload endpoint contract (`multipart` field names, auth).
- WebSocket handshake query/header + event payload shapes (backend §9.7 `x-websocket` panel).
- Refresh-token endpoint semantics (rotate? revoke on logout?).
- Error `meta` content for validation errors (field → message map, for inline form errors).
