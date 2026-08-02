import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/mock_auth_repository.dart';
import '../mock/mock_repositories.dart';
import '../mock/mock_store.dart';
import 'address_repository.dart';
import 'admin_repository.dart';
import 'analytics_repository.dart';
import 'auth_repository.dart';
import 'category_repository.dart';
import 'chat_repository.dart';
import 'delivery_repository.dart';
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

/// Repository provider wiring — every repository is a mock today (backend not
/// live). At the Swagger hand-off each swaps its return value for an
/// `Api…Repository` backed by `apiClientProvider`; screens and controllers
/// are unaffected because they depend on the abstract interfaces only.
final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => MockCategoryRepository(ref.watch(mockStoreProvider)));
final productRepositoryProvider = Provider<ProductRepository>((ref) => MockProductRepository(ref.watch(mockStoreProvider)));
final addressRepositoryProvider = Provider<AddressRepository>((ref) => MockAddressRepository(ref.watch(mockStoreProvider)));
final orderRepositoryProvider = Provider<OrderRepository>((ref) => MockOrderRepository(ref.watch(mockStoreProvider)));
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) => MockWishlistRepository(ref.watch(mockStoreProvider)));
final ratingRepositoryProvider = Provider<RatingRepository>((ref) => MockRatingRepository(ref.watch(mockStoreProvider)));
final walletRepositoryProvider = Provider<WalletRepository>((ref) => MockWalletRepository(ref.watch(mockStoreProvider)));
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => MockPaymentRepository(ref.watch(mockStoreProvider)));
final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) => MockWithdrawalRepository(ref.watch(mockStoreProvider)));
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) => MockDeliveryRepository(ref.watch(mockStoreProvider)));
final chatRepositoryProvider = Provider<ChatRepository>((ref) => MockChatRepository(ref.watch(mockStoreProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => MockNotificationRepository(ref.watch(mockStoreProvider)));
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) => MockReceiptRepository(ref.watch(mockStoreProvider)));
final supportRepositoryProvider = Provider<SupportRepository>((ref) => MockSupportRepository(ref.watch(mockStoreProvider)));
final reportRepositoryProvider = Provider<ReportRepository>((ref) => MockReportRepository(ref.watch(mockStoreProvider)));
final sellerProfileRepositoryProvider = Provider<SellerProfileRepository>((ref) => MockSellerProfileRepository(ref.watch(mockStoreProvider)));
final userRepositoryProvider = Provider<UserRepository>((ref) => MockUserRepository(ref.watch(mockStoreProvider)));
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) => MockAnalyticsRepository(ref.watch(mockStoreProvider)));
final adminRepositoryProvider = Provider<AdminRepository>((ref) => MockAdminRepository(ref.watch(mockStoreProvider)));
