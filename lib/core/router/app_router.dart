import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../features/admin/screens/admin_chat_screen.dart';
import '../../features/admin/screens/admin_activity_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_create_driver_screen.dart';
import '../../features/admin/screens/admin_deliveries_screen.dart';
import '../../features/admin/screens/admin_drivers_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_sellers_screen.dart';
import '../../features/admin/screens/admin_tickets_screen.dart';
import '../../features/admin/screens/admin_withdrawals_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_login_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/buyer/screens/addresses_screen.dart';
import '../../features/buyer/screens/buyer_home_screen.dart';
import '../../features/buyer/screens/buyer_orders_screen.dart';
import '../../features/buyer/screens/buyer_profile_screen.dart';
import '../../features/buyer/screens/buyer_search_screen.dart';
import '../../features/buyer/screens/cart_screen.dart';
import '../../features/buyer/screens/checkout_screen.dart';
import '../../features/buyer/screens/order_detail_screen.dart';
import '../../features/buyer/screens/product_detail_screen.dart';
import '../../features/buyer/screens/wishlist_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/chat_threads_screen.dart';
import '../../features/delivery/screens/delivery_tracking_screen.dart';
import '../../features/delivery/screens/driver_delivery_detail_screen.dart';
import '../../features/delivery/screens/driver_route_screen.dart';
import '../../features/delivery/screens/live_map_screen.dart';
import '../../features/delivery/screens/driver_home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/receipts/screens/receipt_screen.dart';
import '../../features/seller/screens/product_form_screen.dart';
import '../../features/seller/screens/seller_dashboard_screen.dart';
import '../../features/seller/screens/seller_home_screen.dart';
import '../../features/seller/screens/seller_order_detail_screen.dart';
import '../../features/seller/screens/seller_orders_screen.dart';
import '../../features/seller/screens/seller_products_screen.dart';
import '../../features/seller/screens/seller_profile_screen.dart';
import '../../features/settings/screens/profile_edit_screen.dart';
import '../../features/settings/screens/support_screen.dart';
import '../../features/wallet/screens/payment_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/wallet_transactions_screen.dart';
import '../../features/wallet/screens/withdrawal_screen.dart';
import '../../screens/splash_screen.dart';

/// Central route registry (plan §8). Screens navigate with these constants;
/// [routerProvider]'s redirect uses them for auth + role gating (AUTH-06).
abstract final class AppRoutes {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otpLogin = '/login-otp';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // Buyer
  static const String buyerHome = '/buyer/home';
  static const String buyerSearch = '/buyer/search';
  static const String product = '/buyer/product';
  static const String cart = '/buyer/cart';
  static const String checkout = '/buyer/checkout';
  static const String buyerOrders = '/buyer/orders';
  static const String order = '/buyer/orders';
  static const String wishlist = '/buyer/wishlist';
  static const String addresses = '/buyer/addresses';
  static const String buyerProfile = '/buyer/profile';

  // Seller
  static const String sellerHome = '/seller/home';
  static const String sellerProducts = '/seller/products';
  static const String sellerOrders = '/seller/orders';
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerWallet = '/seller/wallet';
  static const String sellerProfile = '/seller/profile';

  // Driver
  static const String driverHome = '/driver/home';

  // Admin
  static const String adminHome = '/admin/home';
  static const String adminSellers = '/admin/sellers';
  static const String adminWithdrawals = '/admin/withdrawals';
  static const String adminDeliveries = '/admin/deliveries';
  static const String adminTickets = '/admin/tickets';
  static const String adminReports = '/admin/reports';
  static const String adminCreateDriver = '/admin/create-driver';
  static const String adminActivity = '/admin/activity';
  static const String adminCategories = '/admin/categories';
  static const String adminDrivers = '/admin/drivers';

  // Shared
  static const String chatThreads = '/chat';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String profile = '/profile';

  /// Pages reachable while logged out.
  static const Set<String> _public = {login, otpLogin, signup, forgotPassword, resetPassword, verifyEmail};

  static bool isPublic(String location) => _public.contains(location);

  static String homeFor(UserRole role) => switch (role) {
        UserRole.buyer => buyerHome,
        UserRole.seller => sellerHome,
        UserRole.admin => adminHome,
        UserRole.driver => driverHome,
      };

  static String productDetail(String id) => '$product/$id';
  static String orderDetail(String id) => '$order/$id';
  static String chat(String threadId) => '$chatThreads/$threadId';
  static String sellerOrderDetail(String id) => '/seller/orders/$id';
  static String sellerProductEdit(String id) => '/seller/products/$id/edit';
  // Role-neutral: any participant in the order (buyer, seller, driver) can
  // follow live delivery — the delivery endpoints resolve ownership server-side.
  static String deliveryTracking(String orderId) => '/tracking/$orderId';
  static String liveMap(String orderId) => '/tracking/$orderId/map';
  static String receipt(String orderId) => '/buyer/receipt/$orderId';
  static String payment(String orderId) => '/buyer/payment/$orderId';
  static String driverDelivery(String id) => '/driver/deliveries/$id';
  static String driverRoute = '/driver/route';
  static String adminThread(String threadId) => '/admin/chat/$threadId';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever auth state changes (restore/login/logout).
  final refresh = ValueNotifier(0);
  // True only for the brief window right after a fresh login/signup/restore —
  // lets the redirect bounce public pages to /verify-email for unverified
  // users, then clears once they reach the verification screen so the public
  // auth screens stay reachable as a sign-out / re-auth escape hatch.
  var justAuthenticated = false;
  ref.listen(authControllerProvider, (previous, next) {
    final prev = previous?.valueOrNull;
    final curr = next.valueOrNull;
    justAuthenticated =
        curr?.status == AuthStatus.authenticated &&
        prev?.status != AuthStatus.authenticated;
    refresh.value++;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final status = auth?.status ?? AuthStatus.unknown;
      final location = state.matchedLocation;

      // Session restore still running — hold on the splash.
      if (status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = auth?.user;

      // Logged out: keep public pages, everything else goes to login. The
      // splash is left alone — AuthGate redirects once its animation ends.
      if (user == null) {
        if (location == AppRoutes.splash || AppRoutes.isPublic(location)) return null;
        return AppRoutes.login;
      }

      // Logged in but not email-verified (AUTH-03, D7 browse-only): the user
      // lands INSIDE the app — a fresh login/signup bounces the public form to
      // the role home — and browses the catalog freely behind the persistent
      // "verify your email" banner (VerifyEmailGate in app.dart). Only order
      // placement is gated, client-side on the checkout screen. /verify-email
      // stays reachable for the deep link and a manual status check, and the
      // public auth pages remain the sign-out / re-auth escape hatch.
      if (user.emailVerified == false) {
        if (location == AppRoutes.verifyEmail) {
          justAuthenticated = false;
          return null;
        }
        if (location == AppRoutes.splash ||
            (justAuthenticated && AppRoutes.isPublic(location))) {
          return AppRoutes.homeFor(user.role);
        }
        if (AppRoutes.isPublic(location)) return null;
        // Once they're inside the app, fresh-auth is consumed — a later visit
        // to a public page (e.g. "Back to sign in") is allowed through.
        justAuthenticated = false;
        if (_roleMismatch(location, user.role)) {
          return AppRoutes.homeFor(user.role);
        }
        return null;
      }

      // Logged in: never land on public pages or a foreign role's home. The
      // splash is again left alone so returning users see it before AuthGate.
      if (location == AppRoutes.splash || AppRoutes.isPublic(location)) {
        return AppRoutes.homeFor(user.role);
      }
      if (_roleMismatch(location, user.role)) {
        return AppRoutes.homeFor(user.role);
      }
      return null;
    },
    routes: [
      // ---- auth ----
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.otpLogin, builder: (_, _) => const OtpLoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, _) => const VerifyEmailScreen()),

      // ---- buyer ----
      GoRoute(path: AppRoutes.buyerHome, builder: (_, _) => const BuyerHomeScreen()),
      GoRoute(path: AppRoutes.buyerSearch, builder: (_, _) => const BuyerSearchScreen()),
      GoRoute(path: '${AppRoutes.product}/:id', builder: (_, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(path: AppRoutes.checkout, builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: AppRoutes.buyerOrders, builder: (_, _) => const BuyerOrdersScreen()),
      GoRoute(path: '${AppRoutes.order}/:id', builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.wishlist, builder: (_, _) => const WishlistScreen()),
      GoRoute(path: AppRoutes.addresses, builder: (_, _) => const AddressesScreen()),
      GoRoute(path: AppRoutes.buyerProfile, builder: (_, _) => const BuyerProfileScreen()),
      GoRoute(path: '${AppRoutes.chatThreads}/:threadId', builder: (_, s) => ChatScreen(threadId: s.pathParameters['threadId']!)),
      GoRoute(path: '/tracking/:orderId', builder: (_, s) => DeliveryTrackingScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/tracking/:orderId/map', builder: (_, s) => LiveMapScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/buyer/receipt/:orderId', builder: (_, s) => ReceiptScreen(orderId: s.pathParameters['orderId']!)),
      GoRoute(path: '/buyer/payment/:orderId', builder: (_, s) => PaymentScreen(orderId: s.pathParameters['orderId']!)),

      // ---- seller ----
      GoRoute(path: AppRoutes.sellerHome, builder: (_, _) => const SellerHomeScreen()),
      GoRoute(path: AppRoutes.sellerProducts, builder: (_, _) => const SellerProductsScreen()),
      GoRoute(path: '/seller/products/new', builder: (_, _) => const ProductFormScreen()),
      GoRoute(path: '/seller/products/:id/edit', builder: (_, s) => ProductFormScreen(id: s.pathParameters['id'])),
      GoRoute(path: AppRoutes.sellerOrders, builder: (_, _) => const SellerOrdersScreen()),
      GoRoute(path: '/seller/orders/:id', builder: (_, s) => SellerOrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.sellerDashboard, builder: (_, _) => const SellerDashboardScreen()),
      GoRoute(path: AppRoutes.sellerWallet, builder: (_, _) => const WalletScreen()),
      GoRoute(path: AppRoutes.sellerProfile, builder: (_, _) => const SellerProfileScreen()),

      // ---- driver ----
      GoRoute(path: AppRoutes.driverHome, builder: (_, _) => const DriverHomeScreen()),
      GoRoute(path: '/driver/deliveries/:id', builder: (_, s) => DriverDeliveryDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.driverRoute, builder: (_, _) => const DriverRouteScreen()),

      // ---- admin ----
      GoRoute(path: AppRoutes.adminHome, builder: (_, _) => const AdminHomeScreen()),
      GoRoute(path: AppRoutes.adminSellers, builder: (_, _) => const AdminSellersScreen()),
      GoRoute(path: AppRoutes.adminWithdrawals, builder: (_, _) => const AdminWithdrawalsScreen()),
      GoRoute(path: AppRoutes.adminDeliveries, builder: (_, _) => const AdminDeliveriesScreen()),
      GoRoute(path: AppRoutes.adminTickets, builder: (_, _) => const AdminTicketsScreen()),
      GoRoute(path: AppRoutes.adminReports, builder: (_, _) => const AdminReportsScreen()),
      GoRoute(path: '/admin/chat/:threadId', builder: (_, s) => AdminChatScreen(threadId: s.pathParameters['threadId']!)),
      GoRoute(path: AppRoutes.adminCreateDriver, builder: (_, _) => const AdminCreateDriverScreen()),
      GoRoute(path: AppRoutes.adminActivity, builder: (_, _) => const AdminActivityScreen()),
      GoRoute(path: AppRoutes.adminCategories, builder: (_, _) => const AdminCategoriesScreen()),
      GoRoute(path: AppRoutes.adminDrivers, builder: (_, _) => const AdminDriversScreen()),

      // ---- shared ----
      GoRoute(path: AppRoutes.chatThreads, builder: (_, _) => const ChatThreadsScreen()),
      GoRoute(path: AppRoutes.walletTransactions, builder: (_, _) => const WalletTransactionsScreen()),
      GoRoute(path: AppRoutes.walletWithdraw, builder: (_, _) => const WithdrawalScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.support, builder: (_, _) => const SupportScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileEditScreen()),
    ],
  );
});

bool _roleMismatch(String location, UserRole role) {
  if (location.startsWith('/buyer')) return role != UserRole.buyer;
  if (location.startsWith('/seller')) return role != UserRole.seller;
  if (location.startsWith('/admin')) return role != UserRole.admin;
  if (location.startsWith('/driver')) return role != UserRole.driver;
  return false;
}
