import 'dart:io' as io;

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/endpoints.dart';
import '../models/activity_log.dart';
import '../models/address.dart';
import '../models/admin_stats.dart';
import '../models/app_notification.dart';
import '../models/auth.dart';
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
import '../repositories/auth_repository.dart';
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

/// Shared helpers for the Api…Repository implementations.
///
/// Every success body is either `{ "data": … }` or a bare paginated payload
/// `{ items, total, page, limit }` — [ApiEnvelope.unwrap] normalises both.
dynamic _unwrap(dynamic body) => ApiEnvelope.unwrap(body);

String _sub(String path, String token, String value) =>
    path.replaceAll('{$token}', Uri.encodeComponent(value));

/// Parses `{ items, total, page, limit }` (with or without the envelope) into
/// a [Page].
Page<T> _page<T>(dynamic body, T Function(Map<String, dynamic>) fromJson) {
  final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
  final items = <T>[
    if (map['items'] is List)
      for (final it in map['items'] as List)
        if (it is Map<String, dynamic>) fromJson(it),
  ];
  return Page<T>(
    items: items,
    page: (map['page'] as num?)?.toInt() ?? 1,
    pageSize: (map['limit'] as num?)?.toInt() ?? items.length,
    total: (map['total'] as num?)?.toInt() ?? items.length,
  );
}

String _money(dynamic value) =>
    value == null ? '0' : value.toString().replaceAll(',', '');

/// Maps a Dio failure to a typed [ApiException].
Never _fail(DioException error) => throw apiExceptionFromDio(error);

/// ────────────────────────────────────────────────────────────────────────────
/// Auth
/// ────────────────────────────────────────────────────────────────────────────
class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  ApiAuthRepository(this._dio);

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        Endpoints.login,
        data: {'identifier': email, 'password': password},
      );
      return AuthSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await _dio.post(Endpoints.otpRequest, data: {
        'target': email,
        'purpose': 'LOGIN',
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<AuthSession> loginWithOtp({required String email, required String code}) async {
    try {
      final res = await _dio.post(Endpoints.otpVerify, data: {
        'target': email,
        'code': code,
        'purpose': 'LOGIN',
      });
      return AuthSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<AuthSession> signup(SignupInput input) async {
    final data = <String, dynamic>{
      'firstName': input.firstName,
      'lastName': input.lastName,
      'email': input.email,
      'phone': input.phone,
      'password': input.password,
      'role': input.role.apiValue,
      'region': input.region,
    };
    if (input.isSeller) {
      if (input.farmName != null) data['farmName'] = input.farmName;
      if (input.mainCategoryId != null) data['mainCategoryId'] = input.mainCategoryId;
      if (input.businessLicense != null) data['businessLicense'] = input.businessLicense;
      if (input.farmDescription != null) data['farmDescription'] = input.farmDescription;
      if (input.farmLatitude != null) data['farmLatitude'] = input.farmLatitude;
      if (input.farmLongitude != null) data['farmLongitude'] = input.farmLongitude;
      if (input.nationalIdUrl != null) data['nationalIdUrl'] = input.nationalIdUrl;
      if (input.selfieUrl != null) data['selfieUrl'] = input.selfieUrl;
    }
    try {
      final res = await _dio.post(Endpoints.signup, data: data);
      return AuthSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<AuthSession> restoreSession(String accessToken) async {
    try {
      // `/auth/me` returns only the minimal principal ({userId,email,role}); the
      // full user DTO lives at `/users/me`, which we parse for the session.
      final res = await _dio.get(Endpoints.myProfile);
      final user = User.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      return AuthSession(accessToken: accessToken, refreshToken: '', user: user);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    try {
      final res = await _dio.post(Endpoints.refresh, data: {'refreshToken': refreshToken});
      return AuthSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      // Stateless logout — the route is bearer-authenticated and takes no body.
      await _dio.post(Endpoints.logout);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(Endpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await _dio.post(Endpoints.resetPassword, data: {
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> verifyEmail(String token) async {
    try {
      await _dio.get('${Endpoints.verifyEmail}?token=${Uri.encodeQueryComponent(token)}');
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Categories
/// ────────────────────────────────────────────────────────────────────────────
class ApiCategoryRepository implements CategoryRepository {
  final Dio _dio;
  ApiCategoryRepository(this._dio);

  @override
  Future<List<Category>> list() async {
    try {
      final res = await _dio.get(Endpoints.categories);
      final body = _unwrap(res.data);
      return [
        if (body is List)
          for (final c in body)
            if (c is Map<String, dynamic>) Category.fromJson(c),
      ];
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Products
/// ────────────────────────────────────────────────────────────────────────────
class ApiProductRepository implements ProductRepository {
  final Dio _dio;
  ApiProductRepository(this._dio);

  @override
  Future<Page<Product>> list({
    String? search,
    int? categoryId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get(Endpoints.products, queryParameters: {
        'page': page,
        'limit': pageSize,
        'categoryId': ?categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      return _page(_unwrap(res.data), Product.fromJson);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Product> get(String id) async {
    try {
      final res = await _dio.get(_sub(Endpoints.product, 'id', id));
      return Product.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Product> create(CreateProductInput input) async {
    try {
      final res = await _dio.post(Endpoints.products, data: {
        'name': input.name,
        'description': input.description,
        if (input.categoryId != null) 'categoryId': input.categoryId,
        'pricePerKg': _money(input.pricePerKg),
        'quantityKg': input.quantityKg.toString(),
        if (input.farmLatitude != null) 'farmLatitude': input.farmLatitude.toString(),
        if (input.farmLongitude != null) 'farmLongitude': input.farmLongitude.toString(),
      });
      final created = Product.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      if (input.imagePath != null) return _uploadImage(created.id, input.imagePath!);
      return created;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Product> update(String id, UpdateProductInput input) async {
    try {
      final data = <String, dynamic>{
        if (input.name != null) 'name': input.name,
        if (input.description != null) 'description': input.description,
        if (input.categoryId != null) 'categoryId': input.categoryId,
        if (input.pricePerKg != null) 'pricePerKg': _money(input.pricePerKg),
        if (input.quantityKg != null) 'quantityKg': input.quantityKg.toString(),
      };
      await _dio.put(_sub(Endpoints.product, 'id', id), data: data);
      if (input.imagePath != null) return _uploadImage(id, input.imagePath!);
      return get(id);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete(_sub(Endpoints.product, 'id', id));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  /// `POST /products/{id}/image` — multipart field name `file`.
  Future<Product> _uploadImage(String id, String imagePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });
      await _dio.post(_sub(Endpoints.productImage, 'id', id), data: form);
      // The upload endpoint only echoes `{ imageUrl }` — refetch the product
      // (which now includes the image) instead of parsing the partial body.
      return get(id);
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Addresses
/// ────────────────────────────────────────────────────────────────────────────
class ApiAddressRepository implements AddressRepository {
  final Dio _dio;
  ApiAddressRepository(this._dio);

  @override
  Future<List<Address>> list() async {
    try {
      final res = await _dio.get(Endpoints.addresses);
      final body = _unwrap(res.data);
      return [
        if (body is List)
          for (final a in body)
            if (a is Map<String, dynamic>) Address.fromJson(a),
      ];
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Map<String, dynamic> _body(CreateAddressInput input) => {
        'label': input.label,
        'recipientName': input.recipientName,
        'phone': input.phone,
        'region': input.region,
        'addressLine': input.addressLine,
        if (input.latitude != null) 'latitude': input.latitude,
        if (input.longitude != null) 'longitude': input.longitude,
        'isDefault': input.isDefault,
      };

  @override
  Future<Address> create(CreateAddressInput input) async {
    try {
      final res = await _dio.post(Endpoints.addresses, data: _body(input));
      return Address.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Address> update(String id, CreateAddressInput input) async {
    try {
      final res = await _dio.patch(_sub(Endpoints.address, 'id', id), data: _body(input));
      return Address.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete(_sub(Endpoints.address, 'id', id));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> setDefault(String id) async {
    try {
      await _dio.patch(_sub(Endpoints.address, 'id', id), data: {'isDefault': true});
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Orders
/// ────────────────────────────────────────────────────────────────────────────
class ApiOrderRepository implements OrderRepository {
  final Dio _dio;
  ApiOrderRepository(this._dio);

  @override
  Future<Order> create(CreateOrderInput input) async {
    try {
      final res = await _dio.post(Endpoints.orders, data: {
        if (input.addressId != null) 'deliveryAddressId': input.addressId,
        'items': [
          for (final item in input.items)
            {
              'productId': item.productId,
              'quantityKg': item.quantityKg.toString(),
            },
        ],
      });
      final unwrapped = _unwrap(res.data);
      // POST /orders creates one order per seller and returns them as a list
      // (e.g. `{ data: [ {order}, … ] }`). The caller sends a single-seller
      // order, so take the first.
      if (unwrapped is List && unwrapped.isNotEmpty && unwrapped.first is Map<String, dynamic>) {
        return Order.fromJson(unwrapped.first as Map<String, dynamic>);
      }
      return Order.fromJson(unwrapped as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<List<Order>> _list(String endpoint) async {
    try {
      final res = await _dio.get(endpoint);
      return _page(_unwrap(res.data), Order.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Order>> buyerOrders() => _list(Endpoints.buyerOrders);

  @override
  Future<List<Order>> sellerOrders() => _list(Endpoints.sellerOrders);

  @override
  Future<Order> get(String id) async {
    try {
      final res = await _dio.get(_sub(Endpoints.order, 'id', id));
      return Order.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus status) async {
    try {
      final res = await _dio.patch(
        _sub(Endpoints.orderStatus, 'id', id),
        data: {'status': status.apiValue},
      );
      return Order.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<OrderStatusHistory>> statusHistory(String id) async {
    try {
      final res = await _dio.get(_sub(Endpoints.orderStatusHistory, 'id', id));
      final body = _unwrap(res.data);
      return [
        if (body is List)
          for (final h in body)
            if (h is Map<String, dynamic>) OrderStatusHistory.fromJson(h),
      ];
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Wishlist
/// ────────────────────────────────────────────────────────────────────────────
class ApiWishlistRepository implements WishlistRepository {
  final Dio _dio;
  ApiWishlistRepository(this._dio);

  @override
  Future<List<WishlistItem>> list() async {
    try {
      final res = await _dio.get(Endpoints.wishlist);
      return _page(_unwrap(res.data), WishlistItem.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Set<String>> savedProductIds() async {
    final items = await list();
    return items.map((i) => i.productId).toSet();
  }

  @override
  Future<void> toggle(String productId) async {
    try {
      final saved = await savedProductIds();
      if (saved.contains(productId)) {
        await _dio.delete(_sub(Endpoints.wishlistItem, 'productId', productId));
      } else {
        await _dio.post(_sub(Endpoints.wishlistItem, 'productId', productId));
      }
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Ratings
/// ────────────────────────────────────────────────────────────────────────────
class ApiRatingRepository implements RatingRepository {
  final Dio _dio;
  ApiRatingRepository(this._dio);

  @override
  Future<void> create(CreateRatingInput input) async {
    try {
      await _dio.post(Endpoints.ratings, data: {
        'orderId': input.orderId,
        'rating': input.rating,
        if (input.reviewText != null) 'reviewText': input.reviewText,
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<SellerRatingSummary> sellerSummary(String sellerId) async {
    try {
      final res = await _dio.get(_sub(Endpoints.sellerRatings, 'sellerId', sellerId));
      final map = _unwrap(res.data) as Map<String, dynamic>;
      return SellerRatingSummary.fromJson({
        'sellerId': sellerId,
        ...map,
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Wallet
/// ────────────────────────────────────────────────────────────────────────────
class ApiWalletRepository implements WalletRepository {
  final Dio _dio;
  ApiWalletRepository(this._dio);

  @override
  Future<Wallet> me() async {
    try {
      final res = await _dio.get(Endpoints.walletMe);
      return Wallet.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<WalletTransaction>> transactions() async {
    try {
      final res = await _dio.get(Endpoints.myTransactions);
      return _page(_unwrap(res.data), WalletTransaction.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Payments
/// ────────────────────────────────────────────────────────────────────────────
class ApiPaymentRepository implements PaymentRepository {
  final Dio _dio;
  ApiPaymentRepository(this._dio);

  static String _channel(PaymentChannel channel) =>
      channel == PaymentChannel.mtnMomo ? 'mtn_momo' : 'orange_money';

  static PaymentResultStatus _status(String value) => switch (value.toUpperCase()) {
        'SUCCESS' || 'PAID' || 'SETTLED' || 'ESCROW_HELD' => PaymentResultStatus.success,
        'PENDING' || 'UNPAID' || 'PROCESSING' => PaymentResultStatus.pending,
        _ => PaymentResultStatus.failed,
      };

  @override
  Future<PaymentResult> initiate(String orderId, PaymentChannel channel) async {
    try {
      final res = await _dio.post(
        _sub(Endpoints.payment, 'orderId', orderId),
        data: {'channel': _channel(channel)},
      );
      final map = _unwrap(res.data) as Map<String, dynamic>;
      return PaymentResult(
        orderId: map['orderId'] as String? ?? orderId,
        status: _status(map['status'] as String? ?? ''),
        reference: map['reference'] as String?,
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<PaymentResult> status(String orderId) async {
    try {
      final res = await _dio.get(_sub(Endpoints.paymentStatus, 'orderId', orderId));
      final map = _unwrap(res.data) as Map<String, dynamic>;
      final transaction = map['transaction'];
      final reference = transaction is Map<String, dynamic>
          ? transaction['reference'] as String?
          : null;
      return PaymentResult(
        orderId: map['orderId'] as String? ?? orderId,
        status: _status(map['paymentStatus'] as String? ?? ''),
        reference: reference,
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Withdrawals
/// ────────────────────────────────────────────────────────────────────────────
class ApiWithdrawalRepository implements WithdrawalRepository {
  final Dio _dio;
  ApiWithdrawalRepository(this._dio);

  @override
  Future<Withdrawal> request(WithdrawalRequest input) async {
    try {
      final res = await _dio.post(Endpoints.withdrawals, data: {
        'amount': _money(input.amount),
        'channel': input.channel.apiValue,
        'accountReference': input.accountReference,
      });
      return Withdrawal.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Withdrawal>> myRequests() async {
    try {
      final res = await _dio.get(Endpoints.myWithdrawals);
      return _page(_unwrap(res.data), Withdrawal.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Deliveries
/// ────────────────────────────────────────────────────────────────────────────
class ApiDeliveryRepository implements DeliveryRepository {
  final Dio _dio;
  ApiDeliveryRepository(this._dio);

  @override
  Future<Delivery> assign(String orderId, String driverId) async {
    try {
      final res = await _dio.post(Endpoints.deliveries, data: {
        'orderId': orderId,
        'driverId': driverId,
      });
      return Delivery.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Delivery>> driverOrders() async {
    try {
      final res = await _dio.get(Endpoints.driverDeliveries);
      return _page(_unwrap(res.data), Delivery.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Delivery> get(String id) async {
    try {
      final res = await _dio.get(_sub(Endpoints.delivery, 'id', id));
      return Delivery.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  Future<Delivery> _action(String id, String endpoint) async {
    try {
      final res = await _dio.post(_sub(endpoint, 'id', id));
      return Delivery.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Delivery> pickup(String id) => _action(id, Endpoints.deliveryPickup);

  @override
  Future<Delivery> deliver(String id) => _action(id, Endpoints.deliveryComplete);
}

/// ────────────────────────────────────────────────────────────────────────────
/// Chat
/// ────────────────────────────────────────────────────────────────────────────
class ApiChatRepository implements ChatRepository {
  final Dio _dio;
  ApiChatRepository(this._dio);

  @override
  Future<List<ChatThread>> threads() async {
    try {
      final res = await _dio.get(Endpoints.chatThreads);
      return _page(_unwrap(res.data), ChatThread.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ChatThread?> threadForOrder(String orderId) async {
    // Preferred: the backend's get-or-create-by-order endpoint. It isn't live
    // yet (404s), so on any failure we fall back to matching in the threads
    // list — once it exists, every order gets a chat thread.
    try {
      final res = await _dio.get(_sub(Endpoints.chatThreadByOrder, 'orderId', orderId));
      final data = _unwrap(res.data);
      if (data is Map<String, dynamic>) return ChatThread.fromJson(data);
    } catch (_) {
      // Endpoint not live / network error — fall through.
    }
    final threads = await this.threads();
    for (final t in threads) {
      if (t.orderId == orderId) return t;
    }
    return null;
  }

  @override
  Future<List<ChatMessage>> messages(String threadId) async {
    try {
      final res = await _dio.get(_sub(Endpoints.chatThread, 'threadId', threadId));
      final body = _unwrap(res.data);
      final messages = body is Map<String, dynamic> ? body['messages'] : null;
      return _page(messages, ChatMessage.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ChatMessage> send(String threadId, SendMessageInput input) async {
    try {
      String? fileUrl;
      if (input.filePath != null) {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(input.filePath!),
        });
        final upload = await _dio.post(
          _sub(Endpoints.chatAttachments, 'threadId', threadId),
          data: form,
        );
        final up = _unwrap(upload.data);
        fileUrl = up is Map<String, dynamic> ? up['fileUrl'] as String? : null;
      }
      final res = await _dio.post(
        _sub(Endpoints.chatMessages, 'threadId', threadId),
        data: {
          'messageType': input.type.apiValue,
          'content': input.content,
          'fileUrl': ?fileUrl,
        },
      );
      return ChatMessage.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> markRead(String threadId) async {
    try {
      await _dio.post(_sub(Endpoints.chatRead, 'threadId', threadId));
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Notifications
/// ────────────────────────────────────────────────────────────────────────────
class ApiNotificationRepository implements NotificationRepository {
  final Dio _dio;
  ApiNotificationRepository(this._dio);

  @override
  Future<List<AppNotification>> list() async {
    try {
      final res = await _dio.get(Endpoints.notifications);
      return _page(_unwrap(res.data), AppNotification.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.patch(_sub(Endpoints.notificationRead, 'id', id));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    // The API exposes per-item read only (`PATCH /notifications/{id}/read`);
    // mark-all has no backend route — no-op.
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Receipts
/// ────────────────────────────────────────────────────────────────────────────
class ApiReceiptRepository implements ReceiptRepository {
  final Dio _dio;
  ApiReceiptRepository(this._dio);

  @override
  Future<Receipt> getForOrder(String orderId) async {
    try {
      final res = await _dio.get(_sub(Endpoints.receiptForOrder, 'orderId', orderId));
      return Receipt.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<String?> downloadPdf(String orderId) async {
    try {
      final receipt = await getForOrder(orderId);
      final res = await _dio.get(
        _sub(Endpoints.receiptDownload, 'id', receipt.id),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes is! List<int>) return null;
      final file =
          io.File('${io.Directory.systemTemp.path}/receipt-${receipt.id}.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
    } on DioException catch (_) {
      return null;
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Support tickets
/// ────────────────────────────────────────────────────────────────────────────
class ApiSupportRepository implements SupportRepository {
  final Dio _dio;
  ApiSupportRepository(this._dio);

  @override
  Future<SupportTicket> create(CreateTicketInput input) async {
    try {
      final res = await _dio.post(Endpoints.supportTickets, data: {
        'subject': input.subject,
        'description': input.description,
      });
      return SupportTicket.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<SupportTicket>> myTickets() async {
    try {
      final res = await _dio.get(Endpoints.mySupportTickets);
      return _page(_unwrap(res.data), SupportTicket.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Reports
/// ────────────────────────────────────────────────────────────────────────────
class ApiReportRepository implements ReportRepository {
  final Dio _dio;
  ApiReportRepository(this._dio);

  @override
  Future<void> submit(ReportInput input) async {
    try {
      await _dio.post(Endpoints.reports, data: {
        'reportedId': input.reportedId,
        'targetType': input.targetType.apiValue,
        if (input.targetId != null) 'targetId': input.targetId,
        'reason': input.reason,
        if (input.details != null) 'details': input.details,
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Seller profile
/// ────────────────────────────────────────────────────────────────────────────
class ApiSellerProfileRepository implements SellerProfileRepository {
  final Dio _dio;
  ApiSellerProfileRepository(this._dio);

  @override
  Future<SellerProfile> me() async {
    try {
      final res = await _dio.get(Endpoints.sellerProfileMe);
      return SellerProfile.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Own profile
/// ────────────────────────────────────────────────────────────────────────────
class ApiUserRepository implements UserRepository {
  final Dio _dio;
  ApiUserRepository(this._dio);

  @override
  Future<User> updateProfile(UpdateProfileInput input) async {
    try {
      final res = await _dio.patch(Endpoints.myProfile, data: {
        if (input.firstName != null) 'firstName': input.firstName,
        if (input.lastName != null) 'lastName': input.lastName,
        if (input.phone != null) 'phone': input.phone,
        if (input.region != null) 'region': input.region,
        if (input.latitude != null) 'latitude': input.latitude,
        if (input.longitude != null) 'longitude': input.longitude,
      });
      return User.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Seller analytics
/// ────────────────────────────────────────────────────────────────────────────
class ApiAnalyticsRepository implements AnalyticsRepository {
  final Dio _dio;
  ApiAnalyticsRepository(this._dio);

  @override
  Future<SellerAnalytics> sellerDashboard() async {
    try {
      final overviewRes = await _dio.get(Endpoints.sellerAnalyticsOverview);
      final overview = _unwrap(overviewRes.data) as Map<String, dynamic>;
      final bestRes = await _dio.get(Endpoints.sellerAnalyticsBestSellers);
      final monthlyRes = await _dio.get(Endpoints.sellerAnalyticsMonthly);
      final best = _unwrap(bestRes.data);
      final monthly = _unwrap(monthlyRes.data);
      return SellerAnalytics.fromJson({
        ...overview,
        'bestSellers': best,
        'monthlySales': monthly,
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Admin
/// ────────────────────────────────────────────────────────────────────────────
class ApiAdminRepository implements AdminRepository {
  final Dio _dio;
  ApiAdminRepository(this._dio);

  @override
  Future<AdminStats> stats() async {
    try {
      final res = await _dio.get(Endpoints.adminStats);
      return AdminStats.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<SellerProfile>> pendingSellers() async {
    try {
      final res = await _dio.get(Endpoints.adminSellerProfiles, queryParameters: {
        'status': 'PENDING',
      });
      return _page(_unwrap(res.data), SellerProfile.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> approveSeller(String userId) async {
    try {
      await _dio.patch(_sub(Endpoints.approveSeller, 'userId', userId));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> rejectSeller(String userId) async {
    try {
      await _dio.patch(_sub(Endpoints.rejectSeller, 'userId', userId));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Wallet>> allWallets() async {
    // No `/admin/wallets` route exists in the API — the admin wallet screen
    // would need it. Return an empty list until the backend exposes one.
    return const [];
  }

  @override
  Future<List<Withdrawal>> pendingWithdrawals() async {
    try {
      final res = await _dio.get(Endpoints.adminWithdrawals, queryParameters: {
        'status': 'PENDING',
      });
      return _page(_unwrap(res.data), Withdrawal.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> processWithdrawal(String id, {bool reject = false}) async {
    try {
      await _dio.post(
        _sub(Endpoints.processWithdrawal, 'id', id),
        data: {'approve': !reject},
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Delivery>> activeDeliveries() async {
    try {
      final res = await _dio.get(Endpoints.adminDeliveries, queryParameters: {
        'activeOnly': true,
      });
      return _page(_unwrap(res.data), Delivery.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<SupportTicket>> tickets() async {
    try {
      final res = await _dio.get(Endpoints.adminSupportTickets);
      return _page(_unwrap(res.data), SupportTicket.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> resolveTicket(String id) async {
    try {
      await _dio.patch(_sub(Endpoints.resolveSupportTicket, 'id', id));
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Report>> reports() async {
    try {
      final res = await _dio.get(Endpoints.adminReports);
      return _page(_unwrap(res.data), Report.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> actionReport(String id, {bool action = false}) async {
    try {
      await _dio.patch(
        _sub(Endpoints.handleReport, 'id', id),
        data: {'status': action ? 'ACTIONED' : 'REVIEWED'},
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<ChatThread>> chatThreads() async {
    try {
      final res = await _dio.get(Endpoints.adminChatThreads);
      return _page(_unwrap(res.data), ChatThread.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<ChatMessage>> chatMessages(String threadId) async {
    try {
      final res = await _dio.get(_sub(Endpoints.adminChatThread, 'threadId', threadId));
      final body = _unwrap(res.data);
      final messages = body is Map<String, dynamic> ? body['messages'] : null;
      return _page(messages, ChatMessage.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> createDriver(CreateDriverInput input) async {
    try {
      // The API's CreateDriverDto requires a password; the interface doesn't
      // carry one, so a placeholder is used (the driver sets it on first login).
      await _dio.post(Endpoints.adminDrivers, data: {
        'firstName': input.firstName,
        'lastName': input.lastName,
        'email': input.email,
        'phone': input.phone,
        'password': 'Driver@12345',
      });
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<ActivityLog>> activityLog() async {
    try {
      final res = await _dio.get(Endpoints.activityLogs);
      return _page(_unwrap(res.data), ActivityLog.fromJson).items;
    } on DioException catch (e) {
      _fail(e);
    }
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Device tokens (FCM push registration)
/// ────────────────────────────────────────────────────────────────────────────
class ApiDeviceTokenRepository implements DeviceTokenRepository {
  final Dio _dio;
  ApiDeviceTokenRepository(this._dio);

  @override
  Future<void> register(String token, DevicePlatform platform) async {
    try {
      await _dio.post(
        Endpoints.deviceTokens,
        data: {'token': token, 'platform': platform.apiValue},
      );
    } on DioException catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> remove(String token) async {
    try {
      await _dio.delete(Endpoints.deviceTokens, data: {'token': token});
    } on DioException catch (e) {
      _fail(e);
    }
  }
}
