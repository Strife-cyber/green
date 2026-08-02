import '../models/page.dart';
import '../models/product.dart';

/// Product catalog — buyer browsing + seller CRUD (BUY-01/02/04, SELL-01).
abstract class ProductRepository {
  /// Search + filter + paginate. `search` matches name/description and, once
  /// the backend joins it, the seller farm name (D3).
  Future<Page<Product>> list({
    String? search,
    int? categoryId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Product> get(String id);

  Future<Product> create(CreateProductInput input);
  Future<Product> update(String id, UpdateProductInput input);
  Future<void> delete(String id);
}

/// [imagePath] is a local file path picked by the user; the repository (mock
/// or API) handles uploading it to the image store.
class CreateProductInput {
  final String name;
  final String? description;
  final int? categoryId;
  final int pricePerKg;
  final double quantityKg;
  final String? imagePath;
  final double? farmLatitude;
  final double? farmLongitude;

  const CreateProductInput({
    required this.name,
    this.description,
    this.categoryId,
    required this.pricePerKg,
    required this.quantityKg,
    this.imagePath,
    this.farmLatitude,
    this.farmLongitude,
  });
}

class UpdateProductInput {
  final String? name;
  final String? description;
  final int? categoryId;
  final int? pricePerKg;
  final double? quantityKg;
  final String? imagePath;

  const UpdateProductInput({
    this.name,
    this.description,
    this.categoryId,
    this.pricePerKg,
    this.quantityKg,
    this.imagePath,
  });
}
