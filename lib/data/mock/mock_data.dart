import '../models/category.dart';
import '../models/enums.dart';
import '../models/seller_profile.dart';
import '../models/user.dart';

/// Seed data for the mock repositories. Replaced by the API at hand-off.
abstract final class MockData {
  /// The 6 seeded categories (BUY-03).
  static const List<Category> categories = [
    Category(id: 1, name: 'Fruits'),
    Category(id: 2, name: 'Vegetables'),
    Category(id: 3, name: 'Grains'),
    Category(id: 4, name: 'Dairy'),
    Category(id: 5, name: 'Organic'),
    Category(id: 6, name: 'Mixed'),
  ];

  static const _buyer = User(
    id: 'u-buyer-1',
    firstName: 'Marie',
    lastName: 'Ngon',
    email: 'buyer@greenish.cm',
    phone: '655000001',
    role: UserRole.buyer,
    region: 'Centre',
    emailVerified: true,
  );

  static const _seller = User(
    id: 'u-seller-1',
    firstName: 'Paul',
    lastName: 'Bello',
    email: 'seller@greenish.cm',
    phone: '655000002',
    role: UserRole.seller,
    region: 'Littoral',
    emailVerified: true,
  );

  static const _admin = User(
    id: 'u-admin-1',
    firstName: 'Claire',
    lastName: 'Fokou',
    email: 'admin@greenish.cm',
    phone: '655000003',
    role: UserRole.admin,
    region: 'Centre',
    emailVerified: true,
  );

  static const _driver = User(
    id: 'u-driver-1',
    firstName: 'Samuel',
    lastName: 'Awa',
    email: 'driver@greenish.cm',
    phone: '655000004',
    role: UserRole.driver,
    region: 'West',
    emailVerified: true,
  );

  /// Approved seller profile for the demo seller login.
  static const sellerProfile = SellerProfile(
    userId: 'u-seller-1',
    farmName: 'Bello Farms',
    mainCategoryId: 1,
    approvalStatus: SellerApprovalStatus.approved,
  );

  /// Resolves a demo user by email so the mock can simulate role-based logins.
  ///
  /// Demo logins: `buyer@`, `seller@`, `admin@`, `driver@` → each role.
  static User userForEmail(String email) {
    final e = email.toLowerCase();
    if (e.contains('seller')) return _seller;
    if (e.contains('admin')) return _admin;
    if (e.contains('driver')) return _driver;
    return _buyer;
  }

  /// A freshly-signed-up seller starts PENDING (AUTH-07), carrying the
  /// identity-document uploads for admin review (AUTH-09).
  static SellerProfile pendingSellerProfile(
    String userId,
    String farmName, {
    int? mainCategoryId,
    String? businessLicense,
    String? farmDescription,
    double? farmLatitude,
    double? farmLongitude,
    String? nationalIdUrl,
    String? selfieUrl,
  }) =>
      SellerProfile(
        userId: userId,
        farmName: farmName,
        mainCategoryId: mainCategoryId,
        businessLicense: businessLicense,
        farmDescription: farmDescription,
        farmLatitude: farmLatitude,
        farmLongitude: farmLongitude,
        nationalIdUrl: nationalIdUrl,
        selfieUrl: selfieUrl,
        approvalStatus: SellerApprovalStatus.pending,
      );
}
