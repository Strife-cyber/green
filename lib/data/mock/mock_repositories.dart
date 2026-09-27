import '../models/activity_log.dart';
import '../models/address.dart';
import '../models/admin_stats.dart';
import '../models/app_notification.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/delivery.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/page.dart';
import '../models/product.dart';
import '../models/rating_review.dart';
import '../models/receipt.dart';
import '../models/report.dart';
import '../models/seller_analytics.dart';
import '../models/seller_profile.dart';
import '../models/support_ticket.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';
import '../models/wishlist_item.dart';
import '../models/withdrawal.dart';
import '../repositories/address_repository.dart';
import '../repositories/admin_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/device_token_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/rating_repository.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/seller_profile_repository.dart';
import '../repositories/support_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/withdrawal_repository.dart';
import '../repositories/wishlist_repository.dart';
import 'mock_data.dart';
import 'mock_store.dart';

/// Simulated network latency for all mock repositories.
const mockLatency = Duration(milliseconds: 400);

Future<void> _delay() => Future<void>.delayed(mockLatency);

int _nextId = 1000;
String _id(String prefix) => 'mock-$prefix-${_nextId++}';

// ---- categories ------------------------------------------------------------

class MockCategoryRepository implements CategoryRepository {
  final MockStore store;
  MockCategoryRepository(this.store);

  @override
  Future<List<Category>> list() async {
    await _delay();
    return List.of(MockData.categories);
  }
}

// ---- products --------------------------------------------------------------

class MockProductRepository implements ProductRepository {
  final MockStore store;
  MockProductRepository(this.store);

  @override
  Future<Page<Product>> list({String? search, int? categoryId, int page = 1, int pageSize = 20}) async {
    await _delay();
    var items = store.products.where((p) => p.isActive).toList();
    if (categoryId != null) items = items.where((p) => p.categoryId == categoryId).toList();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      items = items
          .where((p) => p.name.toLowerCase().contains(q) || (p.sellerName?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    final start = (page - 1) * pageSize;
    final pageItems = start >= items.length ? <Product>[] : items.sublist(start, (start + pageSize).clamp(0, items.length));
    return Page(items: pageItems, page: page, pageSize: pageSize, total: items.length);
  }

  @override
  Future<Product> get(String id) async {
    await _delay();
    return store.products.firstWhere((p) => p.id == id);
  }

  @override
  Future<Product> create(CreateProductInput input) async {
    await _delay();
    final product = Product(
      id: _id('p'),
      sellerId: 'u-seller-1',
      categoryId: input.categoryId,
      name: input.name,
      description: input.description,
      pricePerKg: input.pricePerKg,
      quantityKg: input.quantityKg,
      imageUrl: input.imagePath,
      sellerName: 'Bello Farms',
      categoryName: MockData.categories.firstWhere((c) => c.id == input.categoryId, orElse: () => const Category(id: 0, name: '')).name,
    );
    store.products.insert(0, product);
    return product;
  }

  @override
  Future<Product> update(String id, UpdateProductInput input) async {
    await _delay();
    final index = store.products.indexWhere((p) => p.id == id);
    final current = store.products[index];
    final updated = Product(
      id: current.id,
      sellerId: current.sellerId,
      categoryId: input.categoryId ?? current.categoryId,
      name: input.name ?? current.name,
      description: input.description ?? current.description,
      pricePerKg: input.pricePerKg ?? current.pricePerKg,
      quantityKg: input.quantityKg ?? current.quantityKg,
      imageUrl: input.imagePath ?? current.imageUrl,
      sellerName: current.sellerName,
      categoryName: current.categoryName,
    );
    store.products[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _delay();
    store.products.removeWhere((p) => p.id == id);
  }
}

// ---- addresses -------------------------------------------------------------

class MockAddressRepository implements AddressRepository {
  final MockStore store;
  final List<Address> _addresses = [
    const Address(
      id: 'a-1',
      label: 'Home',
      recipientName: 'Marie Ngon',
      phone: '655000001',
      region: 'Centre',
      addressLine: 'Bastos, Yaoundé',
      latitude: 3.8667,
      longitude: 11.5167,
      isDefault: true,
    ),
    const Address(
      id: 'a-2',
      label: 'Office',
      recipientName: 'Marie Ngon',
      phone: '655000001',
      region: 'Littoral',
      addressLine: 'Akwa, Douala',
      latitude: 4.0511,
      longitude: 9.7679,
    ),
  ];

  MockAddressRepository(this.store);

  @override
  Future<List<Address>> list() async {
    await _delay();
    return List.of(_addresses);
  }

  @override
  Future<Address> create(CreateAddressInput input) async {
    await _delay();
    final address = Address(
      id: _id('a'),
      label: input.label,
      recipientName: input.recipientName,
      phone: input.phone,
      region: input.region,
      addressLine: input.addressLine,
      latitude: input.latitude,
      longitude: input.longitude,
      isDefault: input.isDefault,
    );
    _addresses.add(address);
    return address;
  }

  @override
  Future<Address> update(String id, CreateAddressInput input) async {
    await _delay();
    final index = _addresses.indexWhere((a) => a.id == id);
    _addresses[index] = Address(
      id: id,
      label: input.label,
      recipientName: input.recipientName,
      phone: input.phone,
      region: input.region,
      addressLine: input.addressLine,
      latitude: input.latitude,
      longitude: input.longitude,
      isDefault: input.isDefault,
    );
    return _addresses[index];
  }

  @override
  Future<void> delete(String id) async {
    await _delay();
    _addresses.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> setDefault(String id) async {
    await _delay();
    for (var i = 0; i < _addresses.length; i++) {
      final isDefault = _addresses[i].id == id;
      _addresses[i] = Address(
        id: _addresses[i].id,
        label: _addresses[i].label,
        recipientName: _addresses[i].recipientName,
        phone: _addresses[i].phone,
        region: _addresses[i].region,
        addressLine: _addresses[i].addressLine,
        latitude: _addresses[i].latitude,
        longitude: _addresses[i].longitude,
        isDefault: isDefault,
      );
    }
  }
}

// ---- orders ----------------------------------------------------------------

class MockOrderRepository implements OrderRepository {
  final MockStore store;
  MockOrderRepository(this.store);

  @override
  Future<Order> create(CreateOrderInput input) async {
    await _delay();
    var subtotal = 0;
    final items = <OrderItem>[];
    for (final cartItem in input.items) {
      final product = store.products.firstWhere((p) => p.id == cartItem.productId);
      final lineTotal = (product.pricePerKg * cartItem.quantityKg).round();
      subtotal += lineTotal;
      items.add(OrderItem(
        orderId: _id('o'),
        productId: product.id,
        productName: product.name,
        unitPrice: product.pricePerKg,
        quantityKg: cartItem.quantityKg,
        lineTotal: lineTotal,
      ));
    }
    final orderId = items.isEmpty ? _id('o') : items.first.orderId;
    final order = Order(
      id: orderId,
      buyerId: 'u-buyer-1',
      sellerId: input.sellerId,
      sellerName: 'Bello Farms',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      subtotal: subtotal,
      deliveryFee: input.deliveryFee,
      totalAmount: subtotal + input.deliveryFee,
      items: items,
      placedAt: DateTime.now(),
    );
    store.orders.insert(0, order);
    // Chat thread is auto-created with the order (CHAT-01).
    store.chatThreads.add(ChatThread(
      id: _id('t'),
      orderId: orderId,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      buyerName: 'Marie Ngon',
      sellerName: 'Bello Farms',
    ));
    return order;
  }

  @override
  Future<List<Order>> buyerOrders() async {
    await _delay();
    return List.of(store.orders);
  }

  @override
  Future<List<Order>> sellerOrders() async {
    await _delay();
    return List.of(store.orders);
  }

  @override
  Future<Order> get(String id) async {
    await _delay();
    return _withDeliveryInfo(store.orders.firstWhere((o) => o.id == id));
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    await _delay();
    final index = store.orders.indexWhere((o) => o.id == id);
    final current = store.orders[index];
    final updated = Order(
      id: current.id,
      buyerId: current.buyerId,
      sellerId: current.sellerId,
      sellerName: current.sellerName,
      status: status,
      paymentStatus: current.paymentStatus,
      subtotal: current.subtotal,
      deliveryFee: current.deliveryFee,
      totalAmount: current.totalAmount,
      deliveryAddressLabel: current.deliveryAddressLabel,
      items: current.items,
      placedAt: current.placedAt,
      deliveredAt: status == OrderStatus.delivered ? DateTime.now() : current.deliveredAt,
    );
    store.orders[index] = updated;
    return _withDeliveryInfo(updated);
  }

  /// Mirrors the backend's order-detail payload: attach the assigned delivery
  /// (id + driver name) when the store has one for this order (DEL-02).
  Order _withDeliveryInfo(Order order) {
    Delivery? delivery;
    for (final d in store.deliveries) {
      if (d.orderId == order.id) {
        delivery = d;
        break;
      }
    }
    if (delivery == null) return order;
    return Order(
      id: order.id,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      status: order.status,
      paymentStatus: order.paymentStatus,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      totalAmount: order.totalAmount,
      deliveryAddressLabel: order.deliveryAddressLabel,
      deliveryId: delivery.id,
      deliveryDriverName: delivery.driverName,
      items: order.items,
      placedAt: order.placedAt,
      deliveredAt: order.deliveredAt,
    );
  }

  @override
  Future<List<OrderStatusHistory>> statusHistory(String id) async {
    await _delay();
    return const [];
  }
}

// ---- wishlist --------------------------------------------------------------

class MockWishlistRepository implements WishlistRepository {
  final MockStore store;
  MockWishlistRepository(this.store);

  @override
  Future<Set<String>> savedProductIds() async {
    await _delay();
    return Set.of(store.wishlistProductIds);
  }

  @override
  Future<List<WishlistItem>> list() async {
    await _delay();
    return [for (final id in store.wishlistProductIds) WishlistItem(id: _id('w'), userId: 'u-buyer-1', productId: id)];
  }

  @override
  Future<void> toggle(String productId) async {
    await _delay();
    if (!store.wishlistProductIds.remove(productId)) store.wishlistProductIds.add(productId);
  }
}

// ---- ratings ---------------------------------------------------------------

class MockRatingRepository implements RatingRepository {
  final MockStore store;
  MockRatingRepository(this.store);

  @override
  Future<void> create(CreateRatingInput input) async {
    await _delay();
  }

  @override
  Future<SellerRatingSummary> sellerSummary(String sellerId) async {
    await _delay();
    return const SellerRatingSummary(sellerId: 'u-seller-1', average: 4.6, count: 18);
  }
}

// ---- wallet ----------------------------------------------------------------

class MockWalletRepository implements WalletRepository {
  final MockStore store;
  MockWalletRepository(this.store);

  @override
  Future<Wallet> me() async {
    await _delay();
    // The wallet screen is the seller's (AppRoutes.sellerWallet), so the demo
    // surfaces the seller's balance — including the "ready to withdraw" figure
    // on the seller home queue.
    return MockStore.sellerWallet;
  }

  @override
  Future<List<WalletTransaction>> transactions() async {
    await _delay();
    return List.of(store.transactions);
  }
}

// ---- payments --------------------------------------------------------------

class MockPaymentRepository implements PaymentRepository {
  final MockStore store;
  MockPaymentRepository(this.store);

  @override
  Future<PaymentResult> initiate(String orderId, PaymentChannel channel) async {
    await _delay();
    final result = PaymentResult(
      orderId: orderId,
      status: PaymentResultStatus.success,
      reference: '${channel == PaymentChannel.mtnMomo ? 'MOMO' : 'OM'}-${_id('ref')}',
    );
    // Mirror the backend: a successful payment confirms the order, holds the
    // funds in escrow and auto-assigns a driver (DEL-02) — the buyer never
    // picks one, and the seller never assigns manually.
    _settlePayment(orderId);
    return result;
  }

  void _settlePayment(String orderId) {
    final index = store.orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;
    final order = store.orders[index];
    store.orders[index] = Order(
      id: order.id,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      sellerName: order.sellerName,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.escrowHeld,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      totalAmount: order.totalAmount,
      deliveryAddressLabel: order.deliveryAddressLabel,
      items: order.items,
      placedAt: order.placedAt,
      deliveredAt: order.deliveredAt,
    );
    if (store.deliveries.any((d) => d.orderId == orderId)) return;
    store.deliveries.add(Delivery(
      id: _id('d'),
      orderId: orderId,
      driverId: 'u-driver-1',
      driverName: 'Samuel Awa',
      assignedAt: DateTime.now(),
      orderStatus: OrderStatus.confirmed,
      codeRequired: order.totalAmount > 25000,
      deliveryAddress: Address(
        id: 'a-${order.deliveryAddressLabel ?? 'checkout'}',
        label: order.deliveryAddressLabel ?? 'Delivery',
        recipientName: 'Marie Ngon',
        phone: '655000001',
        region: 'Littoral',
        addressLine: '${order.deliveryAddressLabel ?? 'Akwa'}, Douala',
        latitude: 4.0511,
        longitude: 9.7679,
      ),
    ));
  }

  @override
  Future<PaymentResult> status(String orderId) async {
    await _delay();
    return PaymentResult(orderId: orderId, status: PaymentResultStatus.success);
  }
}

// ---- withdrawals -----------------------------------------------------------

class MockWithdrawalRepository implements WithdrawalRepository {
  final MockStore store;
  MockWithdrawalRepository(this.store);

  @override
  Future<Withdrawal> request(WithdrawalRequest input) async {
    await _delay();
    // The backend verifies `password` server-side (bcrypt) and rejects with
    // "incorrect password" — the mock has no password store, so any non-empty
    // password is accepted and an empty one mimics the rejection.
    if (input.password.trim().isEmpty) {
      throw Exception('incorrect password');
    }
    final withdrawal = Withdrawal(
      id: _id('wd'),
      walletId: 'w-seller-1',
      userId: 'u-seller-1',
      amount: input.amount,
      channel: input.channel,
      accountReference: input.accountReference,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
    );
    store.withdrawals.insert(0, withdrawal);
    return withdrawal;
  }

  @override
  Future<List<Withdrawal>> myRequests() async {
    await _delay();
    return List.of(store.withdrawals);
  }
}

// ---- deliveries ------------------------------------------------------------

class MockDeliveryRepository implements DeliveryRepository {
  final MockStore store;
  MockDeliveryRepository(this.store);

  @override
  Future<List<User>> availableDrivers() async {
    await _delay();
    return const [
      User(id: 'u-driver-1', firstName: 'Jean', lastName: 'Kamdem', email: 'driver@greenish.cm', phone: '655000100', role: UserRole.driver, region: 'Littoral', emailVerified: true),
      User(id: 'u-driver-2', firstName: 'Serge', lastName: 'Tchoua', email: 'driver2@greenish.cm', phone: '655000101', role: UserRole.driver, region: 'Centre', emailVerified: true),
    ];
  }

  /// The code-required threshold shared with the backend (order total above
  /// 25 000 FCFA requires the buyer to enter the emailed 6-digit code).
  static bool isCodeRequired(Order? order) => order != null && order.totalAmount > 25000;

  Order? _orderFor(String orderId) {
    for (final o in store.orders) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  /// Fills `orderStatus`/`codeRequired`/`sellerName` from the linked order when
  /// a response doesn't already carry them (newly assigned deliveries, list
  /// items). `sellerName` powers the driver's "Pick up" task line — the live
  /// delivery payload has no seller, so the mock derives it.
  Delivery _enrich(Delivery d) {
    final order = _orderFor(d.orderId);
    if (order == null) return d;
    return d.copyWith(
      orderStatus: d.orderStatus ?? order.status,
      codeRequired: d.codeRequired || isCodeRequired(order),
      sellerName: d.sellerName ?? order.sellerName,
    );
  }

  @override
  Future<Delivery> assign(String orderId, String driverId) async {
    await _delay();
    final drivers = await availableDrivers();
    String? driverName;
    for (final d in drivers) {
      if (d.id == driverId) {
        driverName = d.fullName;
        break;
      }
    }
    final order = _orderFor(orderId);
    final delivery = Delivery(
      id: _id('d'),
      orderId: orderId,
      sellerName: order?.sellerName,
      driverId: driverId,
      driverName: driverName ?? 'Assigned driver',
      assignedAt: DateTime.now(),
      orderStatus: order?.status,
      codeRequired: isCodeRequired(order),
    );
    store.deliveries.add(delivery);
    return delivery;
  }

  @override
  Future<List<Delivery>> driverOrders() async {
    await _delay();
    return [for (final d in store.deliveries) _enrich(d)];
  }

  @override
  Future<Delivery> get(String id) async {
    await _delay();
    return _enrich(store.deliveries.firstWhere((d) => d.id == id));
  }

  /// No socket server under USE_MOCKS — the driver-side simulated route writes
  /// its fixes here so a buyer/seller's 5s poll sees the same movement.
  @override
  Future<void> reportPosition(String id, double latitude, double longitude) async {
    final index = store.deliveries.indexWhere((d) => d.id == id);
    if (index < 0) return;
    store.deliveries[index] = store.deliveries[index].copyWith(
      currentLatitude: latitude,
      currentLongitude: longitude,
      locationUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<Delivery> pickup(String id) async {
    await _delay();
    final index = store.deliveries.indexWhere((d) => d.id == id);
    final current = store.deliveries[index];
    // Mirror the backend: pickup flips PENDING|CONFIRMED → SHIPPED in one
    // transaction (DEL-01) — the driver's action, not a seller button.
    final order = _orderFor(current.orderId);
    if (order != null) {
      final oi = store.orders.indexWhere((o) => o.id == order.id);
      if (oi >= 0) {
        store.orders[oi] = _orderCopy(order, status: OrderStatus.shipped);
      }
    }
    final updated = current.copyWith(
      pickupConfirmedAt: current.pickupConfirmedAt ?? DateTime.now(),
      orderStatus: OrderStatus.shipped,
    );
    store.deliveries[index] = updated;
    return updated;
  }

  @override
  Future<Delivery> complete(String id) async {
    await _delay();
    final index = store.deliveries.indexWhere((d) => d.id == id);
    final current = store.deliveries[index];
    final order = _orderFor(current.orderId);
    // Mirror the backend: complete requires the order to be SHIPPED (picked
    // up). The code is generated server-side and emailed to the buyer; the
    // mock stores the fixed `482913` only for code-required orders.
    if (!current.isPickupConfirmed || order?.status != OrderStatus.shipped) {
      throw Exception('The delivery must be picked up before completing it.');
    }
    if (isCodeRequired(order)) {
      store.deliveryCodes[id] = '482913';
    }
    final updated = current.copyWith(
      confirmationCodeIssued: true,
      pickupConfirmedAt: current.pickupConfirmedAt ?? DateTime.now(),
    );
    store.deliveries[index] = updated;
    return updated;
  }

  @override
  Future<Delivery> confirm(String id, {String? code}) async {
    await _delay();
    final index = store.deliveries.indexWhere((d) => d.id == id);
    final current = store.deliveries[index];
    final order = _orderFor(current.orderId);
    // One-tap "Got it": the code check is skipped entirely when the order is
    // below the code-required threshold. Code-required orders validate the
    // 6-digit code (wrong code / missing code are rejected).
    if (isCodeRequired(order)) {
      final expected = store.deliveryCodes[id];
      if (expected == null) {
        throw Exception('No confirmation code has been issued for this delivery.');
      }
      if (code == null || expected != code) {
        throw Exception('Invalid confirmation code.');
      }
      store.deliveryCodes.remove(id);
    }
    // Confirm is the ONLY path to DELIVERED (releases escrow + receipt).
    if (order != null) {
      final oi = store.orders.indexWhere((o) => o.id == order.id);
      if (oi >= 0) {
        store.orders[oi] = _orderCopy(
          order,
          status: OrderStatus.delivered,
          paymentStatus: PaymentStatus.settled,
          deliveredAt: DateTime.now(),
        );
      }
    }
    final updated = current.copyWith(
      deliveredAt: DateTime.now(),
      orderStatus: OrderStatus.delivered,
    );
    store.deliveries[index] = updated;
    return updated;
  }

  Order _orderCopy(
    Order order, {
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? deliveredAt,
  }) =>
      Order(
        id: order.id,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        sellerName: order.sellerName,
        status: status ?? order.status,
        paymentStatus: paymentStatus ?? order.paymentStatus,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        totalAmount: order.totalAmount,
        deliveryAddressLabel: order.deliveryAddressLabel,
        items: order.items,
        placedAt: order.placedAt,
        deliveredAt: deliveredAt ?? order.deliveredAt,
      );
}

// ---- chat ------------------------------------------------------------------

class MockChatRepository implements ChatRepository {
  final MockStore store;

  /// Threads the mock user has opened — their badge stays cleared until a new
  /// message lands (mirrors the realtime `message:read` clearing the badge).
  final Set<String> _readThreads = {};

  MockChatRepository(this.store);

  @override
  Future<List<ChatThread>> threads() async {
    await _delay();
    return [for (final t in store.chatThreads) _enrich(t)];
  }

  @override
  Future<ChatThread?> threadForOrder(String orderId) async {
    await _delay();
    for (final t in store.chatThreads) {
      if (t.orderId == orderId) return _enrich(t);
    }
    return null;
  }

  @override
  Future<List<ChatMessage>> messages(String threadId) async {
    await _delay();
    return List.of(store.chatMessages[threadId] ?? const []);
  }

  @override
  Future<ChatMessage> send(String threadId, SendMessageInput input) async {
    await _delay();
    final message = ChatMessage(
      id: _id('m'),
      threadId: threadId,
      senderId: 'u-buyer-1',
      type: input.type,
      content: input.content,
      fileUrl: input.filePath,
      sentAt: DateTime.now(),
      // The mock delivers instantly so the tick progression is visible.
      deliveredAt: DateTime.now(),
    );
    store.chatMessages.putIfAbsent(threadId, () => []).add(message);
    // Keep the thread list preview in sync with the new message.
    final index = store.chatThreads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final t = store.chatThreads[index];
      store.chatThreads[index] = t.copyWith(
        lastMessage: ChatThreadLastMessage(
          content: message.content,
          type: message.type,
          sentAt: message.sentAt,
          mine: true,
        ),
        updatedAt: message.sentAt,
      );
    }
    return message;
  }

  @override
  Future<void> markRead(String threadId) async {
    await _delay();
    _readThreads.add(threadId);
  }

  /// Fills the enriched display fields the backend now packs into
  /// `GET /chat/threads` — the mock derives them from the in-memory store so
  /// the thread list and order-context header stay fully functional without
  /// the backend.
  ChatThread _enrich(ChatThread t) {
    final messages = store.chatMessages[t.id] ?? const <ChatMessage>[];
    ChatMessage? last;
    for (final m in messages) {
      if (last == null || m.sentAt.isAfter(last.sentAt)) last = m;
    }
    Order? order;
    for (final o in store.orders) {
      if (o.id == t.orderId) {
        order = o;
        break;
      }
    }
    final unread = _readThreads.contains(t.id)
        ? 0
        : messages.where((m) => m.senderId != 'u-buyer-1' && m.readAt == null).length;
    return t.copyWith(
      orderStatus: order?.status,
      orderTotal: order?.totalAmount ?? 0,
      productPreview: order == null || order.items.isEmpty
          ? null
          : ChatThreadProductPreview(name: order.items.first.productName),
      lastMessage: last == null
          ? null
          : ChatThreadLastMessage(
              content: last.content,
              type: last.type,
              sentAt: last.sentAt,
              mine: last.senderId == 'u-buyer-1',
            ),
      unreadCount: unread,
      updatedAt: last?.sentAt ?? t.createdAt,
    );
  }
}

// ---- notifications ---------------------------------------------------------

class MockNotificationRepository implements NotificationRepository {
  final MockStore store;
  MockNotificationRepository(this.store);

  @override
  Future<List<AppNotification>> list() async {
    await _delay();
    return List.of(store.notifications);
  }

  @override
  Future<void> markRead(String id) async {
    await _delay();
  }

  @override
  Future<void> markAllRead() async {
    await _delay();
  }
}

// ---- receipts --------------------------------------------------------------

class MockReceiptRepository implements ReceiptRepository {
  final MockStore store;
  MockReceiptRepository(this.store);

  @override
  Future<Receipt> getForOrder(String orderId) async {
    await _delay();
    return seedReceipt;
  }

  @override
  Future<String?> downloadPdf(String orderId) async {
    await _delay();
    return null; // PDF generation is deferred to the backend.
  }
}

// ---- support ---------------------------------------------------------------

class MockSupportRepository implements SupportRepository {
  final MockStore store;
  MockSupportRepository(this.store);

  @override
  Future<SupportTicket> create(CreateTicketInput input) async {
    await _delay();
    final ticket = SupportTicket(
      id: _id('tk'),
      userId: 'u-buyer-1',
      subject: input.subject,
      description: input.description,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
    );
    store.tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<List<SupportTicket>> myTickets() async {
    await _delay();
    return List.of(store.tickets);
  }
}

// ---- reports ---------------------------------------------------------------

class MockReportRepository implements ReportRepository {
  final MockStore store;
  MockReportRepository(this.store);

  @override
  Future<void> submit(ReportInput input) async {
    await _delay();
  }
}

// ---- seller profile / user / analytics -------------------------------------

class MockSellerProfileRepository implements SellerProfileRepository {
  final MockStore store;
  MockSellerProfileRepository(this.store);

  @override
  Future<SellerProfile> me() async {
    await _delay();
    return MockData.sellerProfile;
  }

  @override
  Future<void> update({
    required String farmName,
    required int mainCategoryId,
    String? farmDescription,
    String? businessLicense,
  }) async {
    await _delay(); // No-op — profile data is already seeded in the mock.
  }

  @override
  Future<String> uploadNationalId(String filePath) async {
    await _delay();
    return 'mock://national-id';
  }

  @override
  Future<String> uploadSelfie(String filePath) async {
    await _delay();
    return 'mock://selfie';
  }

  @override
  Future<void> resubmit() async {
    await _delay(); // No-op — the mock seller is already approved.
  }
}

class MockUserRepository implements UserRepository {
  final MockStore store;
  MockUserRepository(this.store);

  @override
  Future<User> updateProfile(UpdateProfileInput input) async {
    await _delay();
    return const User(
      id: 'u-buyer-1',
      firstName: 'Marie',
      lastName: 'Ngon',
      email: 'buyer@greenish.cm',
      role: UserRole.buyer,
      emailVerified: true,
    );
  }
}

class MockAnalyticsRepository implements AnalyticsRepository {
  final MockStore store;
  MockAnalyticsRepository(this.store);

  @override
  Future<SellerAnalytics> sellerDashboard() async {
    await _delay();
    return seedSellerAnalytics;
  }
}

// ---- admin -----------------------------------------------------------------

class MockAdminRepository implements AdminRepository {
  final MockStore store;
  MockAdminRepository(this.store);

  @override
  Future<AdminStats> stats() async {
    await _delay();
    return const AdminStats(
      totalUsers: 1240,
      activeSellers: 320,
      pendingSellers: 5,
      grossRevenue: 15000000,
      commissionEarned: 750000,
      totalOrders: 980,
    );
  }

  @override
  Future<List<SellerProfile>> pendingSellers() async {
    await _delay();
    return [
      const SellerProfile(
        userId: 'u-seller-3',
        farmName: 'Minkoulou Farm',
        mainCategoryId: 2,
        approvalStatus: SellerApprovalStatus.pending,
        farmDescription: 'Family vegetable farm in the Lekié valley. 2 ha of tomatoes, huckleberry and peppers.',
        nationalIdUrl: '',
        selfieUrl: '',
      ),
      const SellerProfile(
        userId: 'u-seller-4',
        farmName: 'Foumbot Coffee',
        mainCategoryId: 3,
        approvalStatus: SellerApprovalStatus.pending,
        farmDescription: 'Smallholder coffee and maize cooperative from the West region.',
        nationalIdUrl: '',
        selfieUrl: '',
      ),
    ];
  }

  @override
  Future<void> approveSeller(String userId) async {
    await _delay();
  }

  @override
  Future<void> rejectSeller(String userId) async {
    await _delay();
  }

  @override
  Future<List<Withdrawal>> pendingWithdrawals() async {
    await _delay();
    return store.withdrawals.where((w) => w.status == WithdrawalStatus.pending).toList();
  }

  @override
  Future<void> processWithdrawal(String id, {bool reject = false}) async {
    await _delay();
  }

  @override
  Future<List<Delivery>> activeDeliveries() async {
    await _delay();
    return store.deliveries.where((d) => !d.isDelivered).toList();
  }

  @override
  Future<List<SupportTicket>> tickets() async {
    await _delay();
    return List.of(store.tickets);
  }

  @override
  Future<void> assignTicket(String id) async {
    await _delay();
    // Flip the ticket to ASSIGNED so the admin shell reflects the state change.
    final index = store.tickets.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final current = store.tickets[index];
      store.tickets[index] = SupportTicket(
        id: current.id,
        userId: current.userId,
        subject: current.subject,
        description: current.description,
        status: TicketStatus.assigned,
        createdAt: current.createdAt,
      );
    }
  }

  @override
  Future<void> resolveTicket(String id) async {
    await _delay();
  }

  @override
  Future<List<Report>> reports() async {
    await _delay();
    return List.of(store.reports);
  }

  @override
  Future<void> actionReport(String id, {bool action = false}) async {
    await _delay();
  }

  @override
  Future<List<ChatThread>> chatThreads() async {
    await _delay();
    return List.of(store.chatThreads);
  }

  @override
  Future<List<ChatMessage>> chatMessages(String threadId) async {
    await _delay();
    return List.of(store.chatMessages[threadId] ?? const []);
  }

  @override
  Future<String?> createDriver(CreateDriverInput input) async {
    await _delay();
    // Simulates the backend generating a temporary password for the driver.
    return 'Temp${DateTime.now().millisecondsSinceEpoch % 100000}@';
  }

  @override
  Future<List<User>> drivers() async {
    await _delay();
    return const [
      User(id: 'u-driver-1', firstName: 'Jean', lastName: 'Kamdem', email: 'driver@greenish.cm', phone: '655000100', role: UserRole.driver, region: 'Littoral', emailVerified: true),
      User(id: 'u-driver-2', firstName: 'Serge', lastName: 'Tchoua', email: 'driver2@greenish.cm', phone: '655000101', role: UserRole.driver, region: 'Centre', emailVerified: true),
    ];
  }

  @override
  Future<List<Order>> orders({OrderStatus? status}) async {
    await _delay();
    // Mock mode doesn't seed orders for the admin picker.
    return const [];
  }

  @override
  Future<List<ActivityLog>> activityLog() async {
    await _delay();
    return seedActivityLog;
  }

  // Categories (ADM-16) — the mock store already ships a seeded category list.
  @override
  Future<void> createCategory(String name) async {
    await _delay();
  }

  @override
  Future<void> renameCategory(int id, String name) async {
    await _delay();
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _delay();
  }
}

// ---- device tokens (push) --------------------------------------------------

class MockDeviceTokenRepository implements DeviceTokenRepository {
  final MockStore store;
  MockDeviceTokenRepository(this.store);

  @override
  Future<void> register(String token, DevicePlatform platform) async {
    await _delay(); // No-op — real tokens live on the backend.
  }

  @override
  Future<void> remove(String token) async {
    await _delay();
  }
}

// Receipt and analytics seeds live in mock_store.dart (`seedReceipt`,
// `seedSellerAnalytics`).
