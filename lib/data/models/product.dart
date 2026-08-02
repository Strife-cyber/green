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
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        sellerId: json['seller_id'] as String? ?? '',
        categoryId: json['category_id'] as int?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        pricePerKg: parseMoney(json['price_per_kg']?.toString()),
        quantityKg: (json['quantity_kg'] as num?)?.toDouble() ?? 0,
        farmLatitude: (json['farm_latitude'] as num?)?.toDouble(),
        farmLongitude: (json['farm_longitude'] as num?)?.toDouble(),
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        sellerName: json['seller_name'] as String?,
        categoryName: json['category_name'] as String?,
      );
}
