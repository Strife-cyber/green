import '../models/receipt.dart';

/// Smart receipts (REC-01/04, PAY-09).
abstract class ReceiptRepository {
  Future<Receipt> getForOrder(String orderId);

  /// The caller's own receipt copies (`GET /receipts/me`) — for admins every
  /// issued receipt lands here too (REC-03 admin copy).
  Future<List<Receipt>> mine();

  /// `GET /receipts/{id}/download` — the rendered PDF bytes (REC-04), null
  /// when the backend has no PDF for the receipt yet.
  Future<List<int>?> downloadPdfBytes(String receiptId);

  /// Convenience: resolves the order's receipt then downloads its PDF bytes.
  Future<List<int>?> downloadOrderPdf(String orderId);
}
