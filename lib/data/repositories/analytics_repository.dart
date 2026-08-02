import '../models/seller_analytics.dart';

/// Seller dashboard aggregates (SELL-03/04/05/07).
abstract class AnalyticsRepository {
  Future<SellerAnalytics> sellerDashboard();
}
