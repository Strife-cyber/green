import '../models/receipt.dart';

/// Smart receipts (REC-01/04, PAY-09).
abstract class ReceiptRepository {
  Future<Receipt> getForOrder(String orderId);

  /// Download the PDF receipt. Returns the bytes (mock) or a file path.
  Future<String?> downloadPdf(String orderId);
}
