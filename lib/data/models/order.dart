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
    this.items = const [],
    this.placedAt,
    this.deliveredAt,
  });

  /// Parses the backend `OrderListItemDto` — camelCase, money as decimal
  /// strings, status enums uppercase.
  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        buyerId: json['buyerId'] as String? ?? '',
        sellerId: json['sellerId'] as String? ?? '',
        sellerName: json['sellerName'] as String?,
        status: OrderStatus.fromApi(json['status'] as String? ?? 'pending'),
        paymentStatus: PaymentStatus.fromApi(json['paymentStatus'] as String? ?? 'unpaid'),
        subtotal: parseMoney(json['subtotal']?.toString()),
        deliveryFee: parseMoney(json['deliveryFee']?.toString()),
        totalAmount: parseMoney(json['totalAmount']?.toString()),
        deliveryAddressLabel: json['deliveryAddressLabel'] as String?,
        items: [
          if (json['items'] is List)
            for (final it in json['items'] as List)
              if (it is Map<String, dynamic>) OrderItem.fromJson(it),
        ],
        placedAt: json['placedAt'] != null ? DateTime.tryParse(json['placedAt'] as String) : null,
        deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
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

  /// Parses the backend `OrderItemListItemDto` — camelCase, money/quantity as
  /// decimal strings.
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        orderId: json['orderId'] as String? ?? '',
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '',
        unitPrice: parseMoney(json['unitPrice']?.toString()),
        quantityKg: _toDouble(json['quantityKg']),
        lineTotal: parseMoney(json['lineTotal']?.toString()),
      );

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
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
        orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
        status: OrderStatus.fromApi(json['status'] as String? ?? 'pending'),
        changedAt: DateTime.tryParse(json['changedAt'] as String? ?? json['changed_at'] as String? ?? '') ??
            DateTime.now(),
        changedBy: json['changedBy'] as String? ?? json['changed_by'] as String?,
      );
}
