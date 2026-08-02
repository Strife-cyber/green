import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/providers.dart';

/// Loads an existing product for editing (`id != null`) and creates/updates
/// on submit. A `null` id means "new product" (SELL-01).
class ProductFormController extends FamilyAsyncNotifier<Product?, String?> {
  @override
  Future<Product?> build(String? arg) async {
    if (arg == null) return null;
    return ref.watch(productRepositoryProvider).get(arg);
  }

  /// Creates or updates the product and returns the saved entity.
  Future<Product> submit({required String? id, required CreateProductInput input}) async {
    if (id == null) return ref.read(productRepositoryProvider).create(input);
    return ref.read(productRepositoryProvider).update(
          id,
          UpdateProductInput(
            name: input.name,
            description: input.description,
            categoryId: input.categoryId,
            pricePerKg: input.pricePerKg,
            quantityKg: input.quantityKg,
            imagePath: input.imagePath,
          ),
        );
  }
}

final productFormControllerProvider =
    AsyncNotifierProvider.family<ProductFormController, Product?, String?>(ProductFormController.new);
