import '../../core/utils/money.dart';
import 'enums.dart';

/// An order-scoped conversation between buyer and seller (CHAT-01). The driver
/// is deliberately NOT a participant — each thread belongs to exactly one order.
class ChatThread {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String? driverId;
  final String? buyerName;
  final String? sellerName;
  final String? driverName;
  final DateTime? createdAt;

  // ---- Enriched fields returned by `GET /chat/threads` -----------------------
  /// The order's live status — drives the status pill on each thread row and
  /// the order-context header in the thread screen.
  final OrderStatus? orderStatus;

  /// Order total in FCFA (int) — shown next to the status pill.
  final int orderTotal;

  /// Product snapshot for the order-context header (name + thumbnail).
  final ChatThreadProductPreview? productPreview;

  /// The user on the other side of the thread (buyer ↔ seller only).
  final String? counterpartyId;
  final String? counterpartyName;

  /// Preview of the most recent message (content, type, who sent it).
  final ChatThreadLastMessage? lastMessage;

  /// Messages the CURRENT user hasn't opened yet — shows the unread badge.
  final int unreadCount;

  /// Recency used to order the list (falls back to [lastMessage]/[createdAt]).
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    this.driverId,
    this.buyerName,
    this.sellerName,
    this.driverName,
    this.createdAt,
    this.orderStatus,
    this.orderTotal = 0,
    this.productPreview,
    this.counterpartyId,
    this.counterpartyName,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  ChatThread copyWith({
    OrderStatus? orderStatus,
    int? orderTotal,
    ChatThreadProductPreview? productPreview,
    String? counterpartyId,
    String? counterpartyName,
    ChatThreadLastMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) =>
      ChatThread(
        id: id,
        orderId: orderId,
        buyerId: buyerId,
        sellerId: sellerId,
        driverId: driverId,
        buyerName: buyerName,
        sellerName: sellerName,
        driverName: driverName,
        createdAt: createdAt,
        orderStatus: orderStatus ?? this.orderStatus,
        orderTotal: orderTotal ?? this.orderTotal,
        productPreview: productPreview ?? this.productPreview,
        counterpartyId: counterpartyId ?? this.counterpartyId,
        counterpartyName: counterpartyName ?? this.counterpartyName,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Parses the backend thread DTO — camelCase. Participant names are derived
  /// client-side, so they stay null from the wire; the enriched `counterparty`
  /// object (id + firstName + lastName) supersedes them when present.
  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final counterparty = json['counterparty'];
    final String? counterpartyId;
    final String? counterpartyName;
    if (counterparty is Map<String, dynamic>) {
      counterpartyId = counterparty['id'] as String?;
      final first = counterparty['firstName'] as String? ?? '';
      final last = counterparty['lastName'] as String? ?? '';
      counterpartyName =
          (first.trim().isEmpty && last.trim().isEmpty) ? null : '${first.trim()} ${last.trim()}'.trim();
    } else {
      counterpartyId = null;
      counterpartyName = null;
    }
    return ChatThread(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
      buyerId: json['buyerId'] as String? ?? json['buyer_id'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? json['driver_id'] as String?,
      buyerName: json['buyerName'] as String?,
      sellerName: json['sellerName'] as String?,
      driverName: json['driverName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      orderStatus: json['orderStatus'] != null
          ? OrderStatus.fromApi(json['orderStatus'] as String)
          : null,
      orderTotal: parseMoney(json['orderTotal']?.toString()),
      productPreview: ChatThreadProductPreview.fromJson(json['productPreview']),
      counterpartyId: counterpartyId,
      counterpartyName: counterpartyName,
      lastMessage: json['lastMessage'] is Map
          ? ChatThreadLastMessage.fromJson(Map<String, dynamic>.from(json['lastMessage'] as Map))
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? (json['unread_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

/// Product snapshot packed into each thread by `GET /chat/threads` — powers the
/// order-context header without a second request (CHAT-01).
class ChatThreadProductPreview {
  final String? name;
  final String? imageUrl;

  const ChatThreadProductPreview({this.name, this.imageUrl});

  /// Accepts either the nested object `{ name, imageUrl }` or a bare string
  /// product name, depending on what the backend packs.
  factory ChatThreadProductPreview.fromJson(dynamic json) {
    if (json is String) return ChatThreadProductPreview(name: json);
    if (json is! Map<String, dynamic>) return const ChatThreadProductPreview();
    return ChatThreadProductPreview(
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }
}

/// Preview of the most recent message — shown in the thread list row (CHAT-01).
class ChatThreadLastMessage {
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool mine;

  const ChatThreadLastMessage({
    this.content = '',
    this.type = MessageType.text,
    required this.sentAt,
    this.mine = false,
  });

  factory ChatThreadLastMessage.fromJson(Map<String, dynamic> json) =>
      ChatThreadLastMessage(
        content: json['content'] as String? ?? '',
        type: MessageType.fromApi(
            json['type'] as String? ?? json['messageType'] as String? ?? 'text'),
        sentAt: DateTime.tryParse(
                json['sentAt'] as String? ?? json['sent_at'] as String? ?? '') ??
            DateTime.now(),
        mine: json['mine'] as bool? ?? false,
      );
}

/// WhatsApp-style delivery state of a message, derived from its server
/// timestamps. Pending/failed are client-side (optimistic send); the rest come
/// from the wire.
enum MessageDeliveryState {
  /// Local-only — rendered optimistically, waiting for the server ack.
  pending,

  /// The server rejected the send — a retry affordance is shown.
  failed,

  /// Acked by the server (`sentAt` present) but not yet delivered/read.
  sent,

  /// Delivered to the recipient (`deliveredAt` present).
  delivered,

  /// Read by the recipient (`readAt` present) — the blue double-check.
  read,
}

/// A message inside a thread: text, image or voice (CHAT-02).
class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? fileUrl;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;

  /// Local-only optimistic message awaiting the server ack (see [deliveryState]).
  final bool pending;

  /// The send failed — [deliveryState] becomes `failed` and a retry affordance
  /// is shown instead of a tick.
  final bool failed;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.type,
    required this.content,
    this.fileUrl,
    required this.sentAt,
    this.readAt,
    this.deliveredAt,
    this.pending = false,
    this.failed = false,
  });

  ChatMessage copyWith({
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    bool? pending,
    bool? failed,
  }) =>
      ChatMessage(
        id: id,
        threadId: threadId,
        senderId: senderId,
        type: type,
        content: content,
        fileUrl: fileUrl,
        sentAt: sentAt ?? this.sentAt,
        readAt: readAt ?? this.readAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );

  bool isMine(String currentUserId) => senderId == currentUserId;

  MessageDeliveryState get deliveryState {
    if (failed) return MessageDeliveryState.failed;
    if (pending) return MessageDeliveryState.pending;
    if (readAt != null) return MessageDeliveryState.read;
    if (deliveredAt != null) return MessageDeliveryState.delivered;
    return MessageDeliveryState.sent;
  }

  /// Parses the backend message DTO — camelCase, `messageType` uppercase.
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['threadId'] as String? ?? json['thread_id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
        type: MessageType.fromApi(json['messageType'] as String? ?? json['message_type'] as String? ?? 'text'),
        content: json['content'] as String? ?? '',
        fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String?,
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? json['sent_at'] as String? ?? '') ?? DateTime.now(),
        readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
        deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
      );
}
