import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';

/// Loads a single [Order] by id (BUY-10).
class OrderDetailController extends AsyncNotifier<Order> {
  String? _id;

  @override
  Future<Order> build() {
    final id = _id;
    if (id == null) {
      // Pending until [load] supplies the id — avoids a spurious error frame.
      return Completer<Order>().future;
    }
    return ref.watch(orderRepositoryProvider).get(id);
  }

  /// Starts (or refreshes) the load for [id].
  Future<void> load(String id) async {
    if (_id == id && state.hasValue) return;
    _id = id;
    ref.invalidateSelf();
    await future;
  }
}

final orderDetailControllerProvider =
    AsyncNotifierProvider<OrderDetailController, Order>(
  OrderDetailController.new,
);
