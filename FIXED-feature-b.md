# FIXED — Feature set B (UX / front-end fixes)

17 verified UX bugs fixed. No `flutter` commands were run; no commits made.

## 1. Driver password no longer hardcoded
- `lib/data/api/api_repositories.dart` — `createDriver` no longer sends a password; sends `region`, reads `tempPassword` from the create response.
- `lib/data/repositories/admin_repository.dart` — `createDriver` now returns `Future<String?>` (temp password, null on none).
- `lib/data/mock/mock_repositories.dart` — mock returns a generated `Temp…` password.
- `lib/features/admin/controllers/admin_create_driver_controller.dart` — `submit` returns `Future<String?>`.
- `lib/features/admin/screens/admin_create_driver_screen.dart` — shows the temp password once in a non-dismissible dialog, then pops.

## 2. Mangled API error messages fixed
- `lib/shared/widgets/error_view.dart` — new `friendlyErrorMessage()` pattern-matches `ApiException.kind` (network/timeout/unauthorized → fixed i18n copy; others → server message or generic fallback). No more string-slicing.
- `lib/shared/widgets/async_view.dart` / `refreshable_async_view.dart` — use `friendlyErrorMessage()`; removed the old `_friendly()`.

## 3. OTP login polish
- `lib/features/auth/screens/otp_login_screen.dart` — copy says "we email you a one-time code"; no demo code `123456` anywhere in the UI; resend button with 30 s cooldown + code-expiry text; `onFieldSubmitted` on the code field.
- `lib/shared/widgets/form_text_field.dart` — added optional `onFieldSubmitted`.

## 4. Login no longer submits per keystroke
- `lib/features/auth/screens/login_screen.dart` — removed `onChanged: (_) => _submit()`; submits on button press or `TextInputAction.done`. Live validation retained.

## 5. Email-verification screen no longer a dead end
- `lib/features/auth/screens/verify_email_screen.dart` — real resend (`authController.resendVerification`) with cooldown, "check status" (`refreshSession`), shows the user's email, i18n copy.
- `lib/data/repositories/auth_repository.dart` + mock + `auth_controller.dart` — `resendVerification(String email)` added.

## 6. Reset-password token from deep link
- `lib/features/auth/screens/reset_password_screen.dart` — post-frame parse of `?token=` (and `/reset-password/<token>` path segment), pre-fills the field; i18n labels; graceful invalid/expired-token message.

## 7. Notifications: taps navigate, mark-all-read works
- `lib/data/api/api_repositories.dart` — `markAllRead` loops the per-item read PATCH over unread items (bounded at 50).
- `lib/features/notifications/screens/notifications_screen.dart` — tap resolves type+data → route (order→order detail, chat→thread, delivery→tracking, wallet→transactions) reusing `PushService.resolvePath`, guarded so a payload without entity keys can't stack a duplicate role home; mark-all-read shows feedback; i18n copy.

## 8. Delivery-code UX
- `lib/data/models/delivery.dart` — added `confirmationCodeIssued` (accepts `confirmationCodeIssued`/`codeIssuedAt`/`confirmationCodeSent`).
- `lib/data/mock/mock_store.dart` / `mock_repositories.dart` — seeded en-route delivery has the code issued; `complete()` marks it issued.
- `lib/features/delivery/screens/delivery_tracking_screen.dart` — code input only once issued, only for buyer role, with "code sent to your email" state; driver/seller see no code UI.
- Socket cold-start connect was already wired in `delivery_tracking_controller.dart` (`socket.connect(... deliveries namespace)`). No resend endpoint exists — the driver issues the code; noted in the screen comment.

## 9. Chat drafts survive send failure
- `lib/features/chat/controllers/chat_controller.dart` — `sendText/sendImage/sendVoice`/`_send` return `Future<bool>`.
- `lib/features/chat/screens/chat_screen.dart` — composer is cleared only on success; the draft stays for retry on failure.

## 10. Wishlist toggle race guarded
- `lib/features/buyer/controllers/wishlist_controller.dart` — in-flight pending-set coalesces concurrent toggles for the same product; `isPending()` exposed.
- `lib/features/buyer/screens/wishlist_screen.dart` — the heart shows a spinner + disabled while pending.

## 11. Notification navigation data
- Covered by #7. Reads exactly what the API returns (`data` map); maps `orderId`/`threadId`/`receiptId`/`deliveryId` via `PushService.resolvePath`, falls back per type. If the backend omits those keys, the tap falls back (wallet→transactions, chat→threads) or is inert.

## 12. Dead route cleanup
- Deleted `lib/shared/widgets/stub_page.dart` (grep-confirmed unused).
- `/buyer/search` is superseded — left untouched (router owned by another agent).

## 13. Profile editing reachable; seller REJECTED re-upload
- `lib/features/buyer/screens/buyer_profile_screen.dart` + `lib/features/seller/screens/seller_profile_screen.dart` — "Edit profile" link → `/profile`.
- Seller REJECTED state: card with re-upload National ID / selfie (`sellerProfileRepositoryProvider.uploadNationalId/uploadSelfie` + PhotoPicker), then refreshes the profile. No separate "re-submit" endpoint exists — uploading re-opens review (noted).

## 14. Admin console polish
- `lib/data/models/report.dart` — optional `reportedName`; `lib/features/admin/screens/admin_reports_screen.dart` shows it (falls back to reportedId).
- `lib/features/admin/screens/admin_sellers_screen.dart` — approve/reject now confirm in a dialog.
- `lib/data/repositories/admin_repository.dart` + API + mock + `admin_tickets_controller.dart` + `admin_tickets_screen.dart` — "Assign to me" via `Endpoints.assignSupportTicket` for open tickets.

## 15. Signup polish
- `lib/features/auth/screens/signup_screen.dart` — Terms of Service / Privacy Policy are tappable links (opens a summary dialog); identity-doc fields labelled optional with explanation; i18n copy.

## 16. Image decode limits
- `lib/shared/widgets/image_network.dart` — `cacheWidth`/`cacheHeight` = widget size × devicePixelRatio (cached_network_image is NOT a dependency, so the existing `Image.network` gets the decode limits).

## 17. i18n coverage (shared strings)
- ~55 keys added to `app_en.arb`/`app_fr.arb` and regenerated into `strings.g.dart` — error messages (network/timeout/unauthorized/generic/retry), OTP/verify/reset copy, delivery confirmation, driver-created, terms/privacy, optional-doc labels, notifications, seller-rejected re-upload.
- Remaining (intentionally not migrated, per "don't attempt full migration"): per-field validator messages in `validators.dart` (`validateRequired(v, 'Token')` etc.), and screen-local labels/empty-states/dialogs across feature screens (e.g. admin buttons, "Contact driver", "Live Tracking", chat composer hints). These are single-language strings that don't affect the shared error/validation surface.

## Files changed (lib/)
```
data/api/api_repositories.dart
data/models/delivery.dart
data/models/report.dart
data/mock/mock_repositories.dart
data/mock/mock_store.dart
data/mock/mock_auth_repository.dart
data/repositories/admin_repository.dart
data/repositories/auth_repository.dart
features/admin/controllers/admin_create_driver_controller.dart
features/admin/controllers/admin_tickets_controller.dart
features/admin/screens/admin_create_driver_screen.dart
features/admin/screens/admin_reports_screen.dart
features/admin/screens/admin_sellers_screen.dart
features/admin/screens/admin_tickets_screen.dart
features/auth/controllers/auth_controller.dart
features/auth/screens/login_screen.dart
features/auth/screens/otp_login_screen.dart
features/auth/screens/reset_password_screen.dart
features/auth/screens/signup_screen.dart
features/auth/screens/verify_email_screen.dart
features/buyer/controllers/wishlist_controller.dart
features/buyer/screens/buyer_profile_screen.dart
features/buyer/screens/wishlist_screen.dart
features/chat/controllers/chat_controller.dart
features/chat/screens/chat_screen.dart
features/delivery/controllers/delivery_tracking_controller.dart
features/delivery/screens/delivery_tracking_screen.dart
features/notifications/screens/notifications_screen.dart
features/seller/screens/seller_profile_screen.dart
l10n/app_en.arb / app_fr.arb / generated/strings.g.dart
shared/widgets/async_view.dart
shared/widgets/error_view.dart
shared/widgets/form_text_field.dart
shared/widgets/image_network.dart
shared/widgets/refreshable_async_view.dart
shared/widgets/stub_page.dart  (deleted)
```
