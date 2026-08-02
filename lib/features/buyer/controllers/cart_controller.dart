import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../data/models/product.dart';

/// One line on the buyer's cart — a product plus the kg quantity. Money is
/// `int` FCFA (line totals are rounded from `pricePerKg * quantityKg`).
class CartLine {
  final Product product;
  final double quantityKg;

  const CartLine({required this.product, required this.quantityKg});

  CartLine copyWith({Product? product, double? quantityKg}) => CartLine(
        product: product ?? this.product,
        quantityKg: quantityKg ?? this.quantityKg,
      );

  /// `pricePerKg * quantityKg` in FCFA, rounded.
  int get lineTotal => (product.pricePerKg * quantityKg).round();
}

/// The buyer's cart — an ordered list of [CartLine]s.
class Cart {
  final List<CartLine> lines;

  const Cart({this.lines = const []});

  bool get isEmpty => lines.isEmpty;

  /// Number of distinct product lines.
  int get itemCount => lines.length;

  /// Sum of every line total in FCFA.
  int get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);
}

const _cartStorageKey = 'greenish.cart.v1';

/// Owns the buyer's cart: add / adjust / remove / clear plus totals. The cart
/// is hydrated from and persisted to [localStoreProvider] so it survives app
/// restarts (BUY-06). Persistence is best-effort — a not-yet-ready
/// SharedPreferences instance falls back to an in-memory cart.
class CartController extends Notifier<Cart> {
  bool _hydrated = false;

  @override
  Cart build() {
    if (!_hydrated) {
      _hydrated = true;
      _hydrate();
    }
    return const Cart();
  }

  void add(Product product, double quantityKg) {
    final index = state.lines.indexWhere((l) => l.product.id == product.id);
    final List<CartLine> lines;
    if (index >= 0) {
      final current = state.lines[index];
      lines = [...state.lines];
      lines[index] = current.copyWith(
        quantityKg: (current.quantityKg + quantityKg).clamp(0.5, _stockLimit(product)).toDouble(),
      );
    } else {
      lines = [
        ...state.lines,
        CartLine(product: product, quantityKg: quantityKg.clamp(0.5, _stockLimit(product)).toDouble()),
      ];
    }
    state = Cart(lines: lines);
    _persist();
  }

  void adjust(String productId, double quantityKg) {
    state = Cart(lines: [
      for (final line in state.lines)
        if (line.product.id == productId)
          line.copyWith(quantityKg: quantityKg.clamp(0.5, _stockLimit(line.product)).toDouble())
        else
          line,
    ]);
    _persist();
  }

  void remove(String productId) {
    state = Cart(lines: [
      for (final line in state.lines)
        if (line.product.id != productId) line,
    ]);
    _persist();
  }

  void clear() {
    state = const Cart();
    _persist();
  }

  // ---- persistence ---------------------------------------------------------

  Future<void> _hydrate() async {
    try {
      final store = await ref.read(localStoreProvider.future);
      final raw = store.getString(_cartStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final lines = [
        for (final item in decoded)
          if (item is Map<String, dynamic>) _lineFromJson(item),
      ];
      if (lines.isNotEmpty) state = Cart(lines: lines);
    } catch (_) {
      // SharedPreferences not ready — start with an empty cart.
    }
  }

  Future<void> _persist() async {
    try {
      final store = await ref.read(localStoreProvider.future);
      await store.setString(
        _cartStorageKey,
        jsonEncode([for (final line in state.lines) _lineToJson(line)]),
      );
    } catch (_) {
      // Best-effort persistence; ignore write failures.
    }
  }

  double _stockLimit(Product product) =>
      product.quantityKg > 0 ? product.quantityKg : 1000;

  Map<String, dynamic> _lineToJson(CartLine line) => {
        'product_id': line.product.id,
        'seller_id': line.product.sellerId,
        'category_id': line.product.categoryId,
        'name': line.product.name,
        'description': line.product.description,
        'price_per_kg': line.product.pricePerKg,
        'stock_kg': line.product.quantityKg,
        'image_url': line.product.imageUrl,
        'seller_name': line.product.sellerName,
        'category_name': line.product.categoryName,
        'line_kg': line.quantityKg,
      };

  CartLine _lineFromJson(Map<String, dynamic> json) => CartLine(
        product: Product(
          id: json['product_id'] as String? ?? '',
          sellerId: json['seller_id'] as String? ?? '',
          categoryId: json['category_id'] as int?,
          name: json['name'] as String? ?? '',
          description: json['description'] as String?,
          pricePerKg: (json['price_per_kg'] as num?)?.toInt() ?? 0,
          quantityKg: (json['stock_kg'] as num?)?.toDouble() ?? 0,
          imageUrl: json['image_url'] as String?,
          sellerName: json['seller_name'] as String?,
          categoryName: json['category_name'] as String?,
        ),
        quantityKg: (json['line_kg'] as num?)?.toDouble() ?? 0,
      );
}

final cartControllerProvider =
    NotifierProvider<CartController, Cart>(CartController.new);
