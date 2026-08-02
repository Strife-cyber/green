import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_analytics.dart';
import '../../../data/repositories/providers.dart';

/// Seller dashboard aggregates (SELL-03/04/05/07).
class SellerDashboardController extends AsyncNotifier<SellerAnalytics> {
  @override
  Future<SellerAnalytics> build() async {
    return ref.watch(analyticsRepositoryProvider).sellerDashboard();
  }
}

final sellerDashboardControllerProvider =
    AsyncNotifierProvider<SellerDashboardController, SellerAnalytics>(SellerDashboardController.new);
