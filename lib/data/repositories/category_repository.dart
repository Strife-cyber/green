import '../models/category.dart';

/// Product categories (BUY-03).
abstract class CategoryRepository {
  Future<List<Category>> list();
}
