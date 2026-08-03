import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_repositories.dart';
import '../mock/mock_auth_repository.dart';
import '../mock/mock_repositories.dart';
import '../mock/mock_store.dart';
import '../../core/network/api_client.dart';
import 'address_repository.dart';
import 'admin_repository.dart';
import 'analytics_repository.dart';
import 'auth_repository.dart';
import 'category_repository.dart';
import 'chat_repository.dart';
import 'delivery_repository.dart';
import 'device_token_repository.dart';
import 'notification_repository.dart';
import 'order_repository.dart';
import 'payment_repository.dart';
import 'product_repository.dart';
import 'rating_repository.dart';
import 'receipt_repository.dart';
import 'report_repository.dart';
import 'seller_profile_repository.dart';
import 'support_repository.dart';
import 'user_repository.dart';
import 'wallet_repository.dart';
import 'withdrawal_repository.dart';
import 'wishlist_repository.dart';

/// Fresh in-memory backend state per ProviderContainer (tests start clean).
final mockStoreProvider = Provider<MockStore>((ref) => MockStore());

/// When `true`, every repository is backed by the in-memory [MockStore];
/// otherwise (the default, since the backend is live) repositories talk to the
/// API through the Dio-backed Api…Repository implementations. Widget tests
/// override this to `true` so no real network happens under test.
final useMocksProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('USE_MOCKS', defaultValue: false),
);

/// Repository provider wiring — each one returns the mock while
/// `useMocksProvider` is true, and the live `Api…Repository` otherwise.
/// Screens and controllers are unaffected because they depend on the abstract
/// interfaces only.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockAuthRepository();
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockCategoryRepository(ref.watch(mockStoreProvider));
  return ApiCategoryRepository(ref.watch(apiClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockProductRepository(ref.watch(mockStoreProvider));
  return ApiProductRepository(ref.watch(apiClientProvider));
});

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockAddressRepository(ref.watch(mockStoreProvider));
  return ApiAddressRepository(ref.watch(apiClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockOrderRepository(ref.watch(mockStoreProvider));
  return ApiOrderRepository(ref.watch(apiClientProvider));
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockWishlistRepository(ref.watch(mockStoreProvider));
  return ApiWishlistRepository(ref.watch(apiClientProvider));
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockRatingRepository(ref.watch(mockStoreProvider));
  return ApiRatingRepository(ref.watch(apiClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockWalletRepository(ref.watch(mockStoreProvider));
  return ApiWalletRepository(ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockPaymentRepository(ref.watch(mockStoreProvider));
  return ApiPaymentRepository(ref.watch(apiClientProvider));
});

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockWithdrawalRepository(ref.watch(mockStoreProvider));
  return ApiWithdrawalRepository(ref.watch(apiClientProvider));
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockDeliveryRepository(ref.watch(mockStoreProvider));
  return ApiDeliveryRepository(ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockChatRepository(ref.watch(mockStoreProvider));
  return ApiChatRepository(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockNotificationRepository(ref.watch(mockStoreProvider));
  return ApiNotificationRepository(ref.watch(apiClientProvider));
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockDeviceTokenRepository(ref.watch(mockStoreProvider));
  return ApiDeviceTokenRepository(ref.watch(apiClientProvider));
});

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockReceiptRepository(ref.watch(mockStoreProvider));
  return ApiReceiptRepository(ref.watch(apiClientProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockSupportRepository(ref.watch(mockStoreProvider));
  return ApiSupportRepository(ref.watch(apiClientProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockReportRepository(ref.watch(mockStoreProvider));
  return ApiReportRepository(ref.watch(apiClientProvider));
});

final sellerProfileRepositoryProvider = Provider<SellerProfileRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockSellerProfileRepository(ref.watch(mockStoreProvider));
  return ApiSellerProfileRepository(ref.watch(apiClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockUserRepository(ref.watch(mockStoreProvider));
  return ApiUserRepository(ref.watch(apiClientProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockAnalyticsRepository(ref.watch(mockStoreProvider));
  return ApiAnalyticsRepository(ref.watch(apiClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (ref.watch(useMocksProvider)) return MockAdminRepository(ref.watch(mockStoreProvider));
  return ApiAdminRepository(ref.watch(apiClientProvider));
});
