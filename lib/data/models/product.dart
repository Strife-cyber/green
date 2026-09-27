import '../../core/utils/money.dart';

/// A seller's listing (BUY-01/02/04, SELL-01). Prices are `int` FCFA.
class Product {
  final String id;
  final String sellerId;
  final int? categoryId;
  final String name;
  final String? description;

  /// FCFA per kg.
  final int pricePerKg;
  final double quantityKg;

  final double? farmLatitude;
  final double? farmLongitude;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  /// Denormalised display fields returned by the API.
  final String? sellerName;
  final String? categoryName;

  /// The farm's region/city label — shown as the "Farm location" row on the
  /// product detail (design 11). Parsed from the nested `seller`/`sellerProfile`
  /// region when the API enriches it.
  final String? farmRegion;
  final double? sellerRating;
  final int? sellerRatingCount;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.name,
    this.description,
    required this.pricePerKg,
    required this.quantityKg,
    this.farmLatitude,
    this.farmLongitude,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.sellerName,
    this.categoryName,
    this.farmRegion,
    this.sellerRating,
    this.sellerRatingCount,
  });

  /// Parses the backend `ProductListItemDto` — camelCase, money/quantity as
  /// decimal strings, with nested `seller` and `category` summaries.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        sellerId: json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
        categoryId: json['categoryId'] as int? ?? json['category_id'] as int?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        pricePerKg: parseMoney(json['pricePerKg']?.toString() ?? json['price_per_kg']?.toString()),
        quantityKg: _toDouble(json['quantityKg'] ?? json['quantity_kg']),
        farmLatitude: _toDoubleOrNull(json['farmLatitude'] ?? json['farm_latitude']),
        farmLongitude: _toDoubleOrNull(json['farmLongitude'] ?? json['farm_longitude']),
        imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
        isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        sellerName: _sellerName(json['seller']),
        categoryName: _categoryName(json['category']),
        farmRegion: _sellerRegion(json['seller']),
        sellerRating: _toDoubleOrNull(
            _sellerMetric(json['seller'], 'rating', 'averageRating')),
        sellerRatingCount: _toIntOrNull(
            _sellerMetric(json['seller'], 'ratingCount', 'reviewsCount')),
      );

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// `seller: { firstName, lastName, sellerProfile: { farmName } }` →
  /// a display name (farm name preferred, else full name).
  static String? _sellerName(dynamic seller) {
    if (seller is! Map<String, dynamic>) return null;
    final farm = seller['sellerProfile'];
    if (farm is Map<String, dynamic> && farm['farmName'] != null) {
      return farm['farmName'] as String;
    }
    final first = seller['firstName'] as String? ?? '';
    final last = seller['lastName'] as String? ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? null : full;
  }

  /// `seller: { region }` / `seller.sellerProfile: { region }` → the farm's
  /// location label for the detail row.
  static String? _sellerRegion(dynamic seller) {
    if (seller is! Map<String, dynamic>) return null;
    final farm = seller['sellerProfile'];
    if (farm is Map<String, dynamic> && farm['region'] != null) {
      return farm['region'] as String;
    }
    return seller['region'] as String?;
  }

  /// Reads `seller[key]` then `seller.sellerProfile[altKey]` — the API packs
  /// seller aggregates on either level depending on the endpoint.
  static dynamic _sellerMetric(dynamic seller, String key, String altKey) {
    if (seller is! Map<String, dynamic>) return null;
    if (seller[key] != null) return seller[key];
    final farm = seller['sellerProfile'];
    if (farm is Map<String, dynamic>) return farm[key] ?? farm[altKey];
    return null;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// `category: { name }` → the category display name.
  static String? _categoryName(dynamic category) {
    if (category is! Map<String, dynamic>) return null;
    return category['name'] as String?;
  }
}
