import '../../core/utils/money.dart';
import 'enums.dart';

/// An order with its line items (BUY-07/09/10, DEL-01). Money is `int` FCFA.
class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? sellerName;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final int subtotal;
  final int deliveryFee;
  final int totalAmount;
  final String? deliveryAddressLabel;

  /// 6-digit code the buyer shares with the driver to confirm hand-off
  /// (DEL-07).
  final String? confirmationCode;

  final List<OrderItem> items;
  final DateTime? placedAt;
  final DateTime? deliveredAt;

  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.sellerName,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.totalAmount,
    this.deliveryAddressLabel,
    this.confirmationCode,
    this.items = const [],
    this.placedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        buyerId: json['buyer_id'] as String? ?? '',
        sellerId: json['seller_id'] as String? ?? '',
        sellerName: json['seller_name'] as String?,
        status: OrderStatus.fromApi(json['status'] as String? ?? 'pending'),
        paymentStatus: PaymentStatus.fromApi(json['payment_status'] as String? ?? 'unpaid'),
        subtotal: parseMoney(json['subtotal']?.toString()),
        deliveryFee: parseMoney(json['delivery_fee']?.toString()),
        totalAmount: parseMoney(json['total_amount']?.toString()),
        deliveryAddressLabel: json['delivery_address_label'] as String?,
        confirmationCode: json['confirmation_code'] as String?,
        items: [
          if (json['items'] is List)
            for (final it in json['items'] as List)
              if (it is Map<String, dynamic>) OrderItem.fromJson(it),
        ],
        placedAt: json['placed_at'] != null ? DateTime.tryParse(json['placed_at'] as String) : null,
        deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'] as String) : null,
      );
}

/// A line on an order — snapshots the product name/price at purchase time.
class OrderItem {
  final String orderId;
  final String productId;
  final String productName;
  final int unitPrice;
  final double quantityKg;
  final int lineTotal;

  const OrderItem({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantityKg,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        orderId: json['order_id'] as String? ?? '',
        productId: json['product_id'] as String,
        productName: json['product_name'] as String? ?? '',
        unitPrice: parseMoney(json['unit_price']?.toString()),
        quantityKg: (json['quantity_kg'] as num?)?.toDouble() ?? 0,
        lineTotal: parseMoney(json['line_total']?.toString()),
      );
}

/// Append-only audit of order status transitions (DEL-01).
class OrderStatusHistory {
  final String id;
  final String orderId;
  final OrderStatus status;
  final DateTime changedAt;
  final String? changedBy;

  const OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.status,
    required this.changedAt,
    this.changedBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) => OrderStatusHistory(
        id: json['id'] as String,
        orderId: json['order_id'] as String? ?? '',
        status: OrderStatus.fromApi(json['status'] as String? ?? 'pending'),
        changedAt: DateTime.tryParse(json['changed_at'] as String? ?? '') ?? DateTime.now(),
        changedBy: json['changed_by'] as String?,
      );
}
