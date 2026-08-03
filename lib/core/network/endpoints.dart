import '../config/app_config.dart';

/// Central endpoint registry — the frontend mirror of the backend Swagger.
///
/// The API is served at the ROOT (Swagger UI is mounted at `/api`). Every
/// constant is the absolute URL for one real route.
abstract final class Endpoints {
  /// Resolved from [AppConfig] — local/staging/production, platform-aware on
  /// Android emulators (10.0.2.2). Override with `--dart-define=API_BASE_URL=…`.
  static String get base => AppConfig.apiBaseUrl;

  // ---- auth ----
  static String get signup => '$base/auth/signup';
  static String get login => '$base/auth/login';
  static String get refresh => '$base/auth/refresh';
  static String get logout => '$base/auth/logout';
  static String get verifyEmail => '$base/auth/verify-email';
  static String get resendVerification => '$base/auth/resend-verification';
  static String get forgotPassword => '$base/auth/forgot-password';
  static String get resetPassword => '$base/auth/reset-password';
  static String get otpRequest => '$base/auth/otp/request';
  static String get otpVerify => '$base/auth/otp/verify';
  static String get me => '$base/auth/me';

  // ---- users ----
  static String get myProfile => '$base/users/me';

  // ---- notifications ----
  static String get notifications => '$base/notifications';
  static String get notificationRead => '$base/notifications/{id}/read';

  // ---- categories ----
  static String get categories => '$base/categories';

  // ---- products ----
  static String get products => '$base/products';
  static String get product => '$base/products/{id}';
  static String get productImage => '$base/products/{id}/image';

  // ---- seller profiles ----
  static String get sellerProfileMe => '$base/seller-profiles/me';
  static String get sellerProfileNationalId => '$base/seller-profiles/me/national-id';
  static String get sellerProfileSelfie => '$base/seller-profiles/me/selfie';
  static String get sellerProfileDocuments => '$base/seller-profiles/me/documents/{kind}';

  // ---- addresses ----
  static String get addresses => '$base/addresses';
  static String get address => '$base/addresses/{id}';

  // ---- orders ----
  static String get orders => '$base/orders';
  static String get buyerOrders => '$base/orders/buyer';
  static String get sellerOrders => '$base/orders/seller';
  static String get order => '$base/orders/{id}';
  static String get orderStatusHistory => '$base/orders/{id}/status-history';
  static String get orderStatus => '$base/orders/{id}/status';

  // ---- wishlist ----
  static String get wishlist => '$base/wishlist';
  static String get wishlistItem => '$base/wishlist/{productId}';

  // ---- ratings ----
  static String get ratings => '$base/ratings';
  static String get sellerRatings => '$base/ratings/seller/{sellerId}';

  // ---- wallets & transactions ----
  static String get walletMe => '$base/wallets/me';
  static String get myTransactions => '$base/transactions/me';
  static String get adminTransactions => '$base/admin/transactions';

  // ---- payments ----
  static String get payment => '$base/payments/{orderId}';
  static String get paymentStatus => '$base/payments/{orderId}/status';

  // ---- withdrawals ----
  static String get withdrawals => '$base/withdrawals';
  static String get myWithdrawals => '$base/withdrawals/me';
  static String get adminWithdrawals => '$base/admin/withdrawals';
  static String get processWithdrawal => '$base/admin/withdrawals/{id}/process';

  // ---- deliveries ----
  static String get deliveries => '$base/deliveries';
  static String get driverDeliveries => '$base/deliveries/driver';
  static String get delivery => '$base/deliveries/{id}';
  static String get deliveryPickup => '$base/deliveries/{id}/pickup';
  static String get deliveryComplete => '$base/deliveries/{id}/complete';
  static String get deliveryConfirm => '$base/deliveries/{id}/confirm';
  static String get adminDeliveries => '$base/admin/deliveries';

  // ---- chat ----
  static String get chatThreads => '$base/chat/threads';
  static String get chatThread => '$base/chat/threads/{threadId}';
  static String get chatThreadByOrder => '$base/chat/threads/order/{orderId}';
  static String get chatMessages => '$base/chat/threads/{threadId}/messages';
  static String get chatRead => '$base/chat/threads/{threadId}/read';
  static String get chatAttachments => '$base/chat/threads/{threadId}/attachments';
  static String get adminChatThreads => '$base/admin/chat/threads';
  static String get adminChatThread => '$base/admin/chat/threads/{threadId}';

  // ---- receipts ----
  static String get receipts => '$base/receipts/me';
  static String get receiptForOrder => '$base/receipts/order/{orderId}';
  static String get receipt => '$base/receipts/{id}';
  static String get receiptDownload => '$base/receipts/{id}/download';

  // ---- reports ----
  static String get reports => '$base/reports';
  static String get myReports => '$base/reports/me';
  static String get adminReports => '$base/admin/reports';
  static String get handleReport => '$base/admin/reports/{id}/handle';

  // ---- support ----
  static String get supportTickets => '$base/support-tickets';
  static String get mySupportTickets => '$base/support-tickets/me';
  static String get adminSupportTickets => '$base/admin/support-tickets';
  static String get assignSupportTicket => '$base/admin/support-tickets/{id}/assign';
  static String get resolveSupportTicket => '$base/admin/support-tickets/{id}/resolve';

  // ---- seller analytics ----
  static String get sellerAnalyticsOverview => '$base/seller-analytics/overview';
  static String get sellerAnalyticsBestSellers => '$base/seller-analytics/best-sellers';
  static String get sellerAnalyticsMonthly => '$base/seller-analytics/monthly';

  // ---- admin ----
  static String get adminStats => '$base/admin/stats';
  static String get adminSellerProfiles => '$base/admin/seller-profiles';
  static String get adminSellerProfile => '$base/admin/seller-profiles/{userId}';
  static String get approveSeller => '$base/admin/seller-profiles/{userId}/approve';
  static String get rejectSeller => '$base/admin/seller-profiles/{userId}/reject';
  static String get adminSellerDocuments => '$base/admin/seller-profiles/{userId}/documents/{kind}';
  static String get adminAdmins => '$base/admin/admins';
  static String get adminAdminRole => '$base/admin/admins/{userId}/role';
  static String get adminDrivers => '$base/admin/drivers';
  static String get activityLogs => '$base/admin/activity-logs';

  // ---- platform config ----
  static String get platformConfig => '$base/platform-config';
  static String get platformConfigKey => '$base/platform-config/{key}';
}
