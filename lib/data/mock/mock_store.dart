import '../models/activity_log.dart';
import '../models/address.dart';
import '../models/app_notification.dart';
import '../models/chat.dart';
import '../models/delivery.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/receipt.dart';
import '../models/report.dart';
import '../models/seller_analytics.dart';
import '../models/support_ticket.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';
import '../models/withdrawal.dart';

/// In-memory state shared by the mock repositories. A fresh store is created
/// per ProviderContainer so tests start clean.
class MockStore {
  final List<Product> products;
  final List<Order> orders;
  final Map<String, List<ChatMessage>> chatMessages;
  final List<ChatThread> chatThreads;
  final List<AppNotification> notifications;
  final List<Withdrawal> withdrawals;
  final List<SupportTicket> tickets;
  final List<Report> reports;
  final List<Delivery> deliveries;
  final List<WalletTransaction> transactions;
  final Set<String> wishlistProductIds;

  /// Delivery confirmation codes issued by [MockDeliveryRepository.complete],
  /// keyed by delivery id (DEL-07). The code is never exposed on the model —
  /// the buyer confirms it via [MockDeliveryRepository.confirm].
  final Map<String, String> deliveryCodes;

  MockStore()
      : products = List.of(seedProducts),
        orders = List.of(seedOrders),
        chatMessages = {for (final t in seedThreads) t.id: List.of(seedMessagesFor(t.id))},
        chatThreads = List.of(seedThreads),
        notifications = List.of(seedNotifications),
        withdrawals = List.of(seedWithdrawals),
        tickets = List.of(seedTickets),
        reports = List.of(seedReports),
        deliveries = List.of(seedDeliveries),
        transactions = List.of(seedTransactions),
        wishlistProductIds = {'p-tomatoes'},
        // No code is issued until the driver completes a delivery (DEL-07);
        // only code-required orders store one (the buyer confirms with it).
        deliveryCodes = {};

  static const wallet = Wallet(id: 'w-buyer-1', userId: 'u-buyer-1', balance: 25000, escrowBalance: 0);
  static const sellerWallet = Wallet(id: 'w-seller-1', userId: 'u-seller-1', balance: 85000, escrowBalance: 12000);
}

// ---- seeds -----------------------------------------------------------------

const seedProducts = <Product>[
  Product(
    id: 'p-tomatoes',
    sellerId: 'u-seller-1',
    categoryId: 2,
    name: 'Fresh Tomatoes',
    description: 'Ripe, vine-grown tomatoes from Bello Farms.',
    pricePerKg: 600,
    quantityKg: 120,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Vegetables',
  ),
  Product(
    id: 'p-plantain',
    sellerId: 'u-seller-1',
    categoryId: 6,
    name: 'Green Plantains',
    description: 'Starchy green plantains, great for cooking.',
    pricePerKg: 450,
    quantityKg: 200,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Mixed',
  ),
  Product(
    id: 'p-avocado',
    sellerId: 'u-seller-1',
    categoryId: 1,
    name: 'Hass Avocados',
    description: 'Creamy avocados harvested this week.',
    pricePerKg: 1500,
    quantityKg: 60,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Fruits',
  ),
  Product(
    id: 'p-honey',
    sellerId: 'u-seller-1',
    categoryId: 5,
    name: 'Pure Forest Honey',
    description: 'Unprocessed honey from the West region.',
    pricePerKg: 8000,
    quantityKg: 25,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Organic',
  ),
  Product(
    id: 'p-yam',
    sellerId: 'u-seller-1',
    categoryId: 3,
    name: 'White Yams',
    description: 'Large yam tubers, high starch content.',
    pricePerKg: 500,
    quantityKg: 300,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Grains',
  ),
  Product(
    id: 'p-cassava',
    sellerId: 'u-seller-1',
    categoryId: 3,
    name: 'Cassava Roots',
    description: 'Sweet cassava, ideal for gari and fufu.',
    pricePerKg: 350,
    quantityKg: 400,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Grains',
  ),
  Product(
    id: 'p-peanuts',
    sellerId: 'u-seller-1',
    categoryId: 3,
    name: 'Ground Peanuts',
    description: 'Roasted peanuts by the kilo.',
    pricePerKg: 1200,
    quantityKg: 80,
    imageUrl: null,
    sellerName: 'Bello Farms',
    categoryName: 'Grains',
  ),
  Product(
    id: 'p-milk',
    sellerId: 'u-seller-2',
    categoryId: 4,
    name: 'Fresh Cow Milk',
    description: 'Pasteurised whole milk, delivered chilled.',
    pricePerKg: 900,
    quantityKg: 50,
    imageUrl: null,
    sellerName: 'Nkam Dairy',
    categoryName: 'Dairy',
  ),
];

final seedOrders = <Order>[
  Order(
    // o-1: placed, unpaid — the buyer's "Pay now" demo.
    id: 'o-1',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    sellerName: 'Bello Farms',
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
    subtotal: 3000,
    deliveryFee: 500,
    totalAmount: 3500,
    deliveryAddressLabel: 'Home',
    items: [
      OrderItem(orderId: 'o-1', productId: 'p-tomatoes', productName: 'Fresh Tomatoes', unitPrice: 600, quantityKg: 5, lineTotal: 3000),
    ],
    placedAt: DateTime(2026, 8, 16, 10, 30),
  ),
  Order(
    // o-2: delivered history.
    id: 'o-2',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    sellerName: 'Bello Farms',
    status: OrderStatus.delivered,
    paymentStatus: PaymentStatus.settled,
    subtotal: 2250,
    deliveryFee: 500,
    totalAmount: 2750,
    deliveryAddressLabel: 'Office',
    items: [
      OrderItem(orderId: 'o-2', productId: 'p-plantain', productName: 'Green Plantains', unitPrice: 450, quantityKg: 5, lineTotal: 2250),
    ],
    placedAt: DateTime(2026, 8, 10, 9, 0),
    deliveredAt: DateTime(2026, 8, 10, 14, 20),
  ),
  Order(
    // o-3: paid, confirmed — awaits the seller preparing it.
    id: 'o-3',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    sellerName: 'Bello Farms',
    status: OrderStatus.confirmed,
    paymentStatus: PaymentStatus.escrowHeld,
    subtotal: 4500,
    deliveryFee: 500,
    totalAmount: 5000,
    deliveryAddressLabel: 'Bepanda',
    items: [
      OrderItem(orderId: 'o-3', productId: 'p-avocado', productName: 'Hass Avocados', unitPrice: 1500, quantityKg: 3, lineTotal: 4500),
    ],
    placedAt: DateTime(2026, 8, 17, 8, 45),
  ),
  Order(
    // o-4: paid, confirmed, high total → the buyer must enter a code.
    id: 'o-4',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    sellerName: 'Bello Farms',
    status: OrderStatus.confirmed,
    paymentStatus: PaymentStatus.escrowHeld,
    subtotal: 28000,
    deliveryFee: 500,
    totalAmount: 28500,
    deliveryAddressLabel: 'Bonabéri',
    items: [
      OrderItem(orderId: 'o-4', productId: 'p-honey', productName: 'Pure Forest Honey', unitPrice: 8000, quantityKg: 3.5, lineTotal: 28000),
    ],
    placedAt: DateTime(2026, 8, 17, 9, 15),
  ),
  Order(
    // o-5: paid, picked up, on the way — the buyer's one-tap "Got it" demo.
    id: 'o-5',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    sellerName: 'Bello Farms',
    status: OrderStatus.shipped,
    paymentStatus: PaymentStatus.escrowHeld,
    subtotal: 1800,
    deliveryFee: 600,
    totalAmount: 2400,
    deliveryAddressLabel: 'Home',
    items: [
      OrderItem(orderId: 'o-5', productId: 'p-plantain', productName: 'Green Plantains', unitPrice: 450, quantityKg: 4, lineTotal: 1800),
    ],
    placedAt: DateTime(2026, 8, 18, 11, 0),
  ),
];

const seedThreads = <ChatThread>[
  ChatThread(
    id: 't-1',
    orderId: 'o-1',
    buyerId: 'u-buyer-1',
    sellerId: 'u-seller-1',
    buyerName: 'Marie Ngon',
    sellerName: 'Bello Farms',
  ),
];

List<ChatMessage> seedMessagesFor(String threadId) => [
      ChatMessage(
        id: 'm-1',
        threadId: threadId,
        senderId: 'u-buyer-1',
        type: MessageType.text,
        content: 'Hello! Is the delivery available this afternoon?',
        sentAt: DateTime(2026, 7, 30, 10, 45),
      ),
      ChatMessage(
        id: 'm-2',
        threadId: threadId,
        senderId: 'u-seller-1',
        type: MessageType.text,
        content: 'Yes, we can arrange it before 6pm.',
        sentAt: DateTime(2026, 7, 30, 10, 50),
      ),
    ];

final seedNotifications = <AppNotification>[
  AppNotification(
    id: 'n-1',
    userId: 'u-buyer-1',
    type: NotificationType.order,
    title: 'Order confirmed',
    body: 'Your order #o-1 has been confirmed by Bello Farms.',
    createdAt: DateTime(2026, 7, 30, 10, 35),
  ),
  AppNotification(
    id: 'n-2',
    userId: 'u-buyer-1',
    type: NotificationType.delivery,
    title: 'Out for delivery',
    body: 'Your order #o-2 was delivered.',
    createdAt: DateTime(2026, 7, 25, 14, 21),
  ),
];

final seedWithdrawals = <Withdrawal>[
  Withdrawal(
    id: 'wd-1',
    walletId: 'w-seller-1',
    userId: 'u-seller-1',
    amount: 50000,
    channel: WithdrawalChannel.mtnMomo,
    accountReference: '655000002',
    status: WithdrawalStatus.pending,
    requestedAt: DateTime(2026, 7, 29, 16, 0),
  ),
];

final seedTickets = <SupportTicket>[
  SupportTicket(
    id: 'tk-1',
    userId: 'u-buyer-1',
    subject: 'Delivery delay',
    description: 'My order has not arrived yet, please help.',
    status: TicketStatus.open,
    createdAt: DateTime(2026, 7, 29, 12, 0),
  ),
];

final seedReports = <Report>[
  Report(
    id: 'r-1',
    reporterId: 'u-buyer-1',
    reportedId: 'u-seller-2',
    targetType: ReportTargetType.chat,
    targetId: 'm-3',
    reason: 'Spam',
    status: ReportStatus.open,
    createdAt: DateTime(2026, 7, 28, 18, 0),
  ),
];

/// Seeds the deliveries consistent with the new lifecycle (payment →
/// auto-assign → pickup → SHIPPED → buyer confirm → DELIVERED). Each carries
/// the order's destination coordinates — WGS84 Douala neighbourhoods.
final seedDeliveries = <Delivery>[
  Delivery(
    // d-1: picked up, on the way to the buyer (order o-5 is SHIPPED).
    id: 'd-1',
    orderId: 'o-5',
    driverId: 'u-driver-1',
    driverName: 'Samuel Awa',
    assignedAt: DateTime(2026, 8, 18, 10, 0),
    pickupConfirmedAt: DateTime(2026, 8, 18, 10, 30),
    // A little off the drop-off so the driver task card shows a real distance.
    currentLatitude: 4.0391,
    currentLongitude: 9.7513,
    locationUpdatedAt: DateTime(2026, 8, 18, 10, 35),
    orderStatus: OrderStatus.shipped,
    codeRequired: false,
    deliveryAddress: const Address(
      id: 'a-1',
      label: 'Home',
      recipientName: 'Marie Ngon',
      phone: '655000001',
      region: 'Littoral',
      addressLine: 'Akwa, Douala',
      latitude: 4.0511,
      longitude: 9.7679,
      isDefault: true,
    ),
  ),
  Delivery(
    // d-2: assigned, awaiting pickup (order o-3 is CONFIRMED).
    id: 'd-2',
    orderId: 'o-3',
    driverId: 'u-driver-1',
    driverName: 'Samuel Awa',
    assignedAt: DateTime(2026, 8, 17, 9, 30),
    orderStatus: OrderStatus.confirmed,
    codeRequired: false,
    deliveryAddress: const Address(
      id: 'a-3',
      label: 'Bepanda',
      recipientName: 'Marie Ngon',
      phone: '655000001',
      region: 'Littoral',
      addressLine: 'Bepanda, Douala',
      latitude: 4.0331,
      longitude: 9.7534,
    ),
  ),
  Delivery(
    // d-3: assigned, awaiting pickup, code required (order o-4 is CONFIRMED).
    id: 'd-3',
    orderId: 'o-4',
    driverId: 'u-driver-1',
    driverName: 'Samuel Awa',
    assignedAt: DateTime(2026, 8, 17, 10, 0),
    orderStatus: OrderStatus.confirmed,
    codeRequired: true,
    deliveryAddress: const Address(
      id: 'a-4',
      label: 'Bonabéri',
      recipientName: 'Marie Ngon',
      phone: '655000001',
      region: 'Littoral',
      addressLine: 'Bonabéri, Douala',
      latitude: 4.0831,
      longitude: 9.6880,
    ),
  ),
];

final seedTransactions = <WalletTransaction>[
  WalletTransaction(
    id: 'tx-1',
    walletId: 'w-buyer-1',
    orderId: 'o-2',
    type: TransactionType.paymentIn,
    status: TransactionStatus.reconciled,
    amount: 2750,
    balanceAfter: 27750,
    reference: 'MOMO-123456',
    createdAt: DateTime(2026, 7, 25, 14, 20),
  ),
  WalletTransaction(
    id: 'tx-2',
    walletId: 'w-seller-1',
    orderId: 'o-2',
    type: TransactionType.escrowRelease,
    status: TransactionStatus.reconciled,
    amount: 2612,
    balanceAfter: 8612,
    createdAt: DateTime(2026, 7, 25, 14, 20),
  ),
  WalletTransaction(
    id: 'tx-3',
    walletId: 'w-seller-1',
    orderId: 'o-2',
    type: TransactionType.commission,
    status: TransactionStatus.reconciled,
    amount: -138,
    balanceAfter: 8474,
    createdAt: DateTime(2026, 7, 25, 14, 20),
  ),
];

/// Seeded admin activity audit trail (ADM-15): logins, payments, withdrawals,
/// approvals and an OTP sign-in.
final seedActivityLog = <ActivityLog>[
  ActivityLog(
    id: 'al-1',
    userId: 'u-buyer-1',
    actorName: 'Marie Ngon',
    action: 'login',
    details: 'Signed in with password',
    createdAt: DateTime(2026, 7, 30, 8, 15),
  ),
  ActivityLog(
    id: 'al-2',
    userId: 'u-seller-1',
    actorName: 'Paul Bello',
    action: 'payment',
    details: 'Escrow settled for order #o-2 (2 612 FCFA)',
    createdAt: DateTime(2026, 7, 30, 9, 40),
  ),
  ActivityLog(
    id: 'al-3',
    userId: 'u-seller-1',
    actorName: 'Paul Bello',
    action: 'withdrawal',
    details: 'Requested 50 000 FCFA via MTN MoMo',
    createdAt: DateTime(2026, 7, 29, 16, 5),
  ),
  ActivityLog(
    id: 'al-4',
    userId: 'u-seller-3',
    actorName: 'Minkoulou Farm',
    action: 'approval',
    details: 'Seller application approved by Claire Fokou',
    createdAt: DateTime(2026, 7, 28, 11, 20),
  ),
  ActivityLog(
    id: 'al-5',
    userId: 'u-buyer-1',
    actorName: 'Marie Ngon',
    action: 'otp_login',
    details: 'Signed in with an email one-time code',
    createdAt: DateTime(2026, 7, 28, 19, 55),
  ),
];

final seedReceipt = Receipt(
  id: 'rc-1',
  receiptNumber: 'GRN-2026-000001',
  orderId: 'o-2',
  amount: 2750,
  deliveryFee: 500,
  commission: 138,
  status: ReceiptStatus.issued,
  issuedAt: DateTime(2026, 7, 25, 14, 20),
);

final seedSellerAnalytics = SellerAnalytics(
  weeklyRevenue: 250000,
  totalCustomers: 42,
  averageRating: 4.6,
  ratingCount: 18,
  bestSellers: [
    BestSeller(productId: 'p-tomatoes', name: 'Fresh Tomatoes', quantitySold: 320, revenue: 192000),
    BestSeller(productId: 'p-plantain', name: 'Green Plantains', quantitySold: 180, revenue: 81000),
    BestSeller(productId: 'p-avocado', name: 'Hass Avocados', quantitySold: 60, revenue: 90000),
  ],
  monthlySales: [
    SalesPoint(day: DateTime(2026, 7, 27), amount: 45000),
    SalesPoint(day: DateTime(2026, 7, 28), amount: 62000),
    SalesPoint(day: DateTime(2026, 7, 29), amount: 38000),
    SalesPoint(day: DateTime(2026, 7, 30), amount: 54000),
    SalesPoint(day: DateTime(2026, 7, 31), amount: 51000),
  ],
);
