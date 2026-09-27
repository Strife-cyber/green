import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_analytics.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// Seller dashboard aggregates (SELL-03/04/05/07). Scoped to the signed-in
/// user so an account switch can't show the previous seller's numbers.
class SellerDashboardController extends AsyncNotifier<SellerAnalytics> {
  @override
  Future<SellerAnalytics> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const SellerAnalytics(
        weeklyRevenue: 0,
        totalCustomers: 0,
        averageRating: 0,
        ratingCount: 0,
      );
    }
    return ref.watch(analyticsRepositoryProvider).sellerDashboard();
  }

  /// Re-fetches the dashboard (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final sellerDashboardControllerProvider =
    AsyncNotifierProvider<SellerDashboardController, SellerAnalytics>(SellerDashboardController.new);
