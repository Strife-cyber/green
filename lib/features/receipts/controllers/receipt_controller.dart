import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../data/models/receipt.dart';
import '../../../data/repositories/providers.dart';

/// Loads the smart receipt issued for an order (REC-01).
class ReceiptController extends FamilyAsyncNotifier<Receipt, String> {
  @override
  Future<Receipt> build(String orderId) =>
      ref.watch(receiptRepositoryProvider).getForOrder(orderId);

  /// Download the PDF copy. Returns the local path when the backend is live,
  /// `null` today (the mock defers PDF generation).
  Future<String?> download() => ref.read(receiptRepositoryProvider).downloadPdf(arg);
}

final receiptControllerProvider =
    AsyncNotifierProvider.family<ReceiptController, Receipt, String>(ReceiptController.new);

/// The order a receipt belongs to — drives the buyer/seller summary (REC-03).
final receiptOrderProvider =
    FutureProvider.family<Order, String>((ref, orderId) => ref.watch(orderRepositoryProvider).get(orderId));
