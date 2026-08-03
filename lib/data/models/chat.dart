import 'enums.dart';

/// An order-scoped conversation between buyer/seller/driver (CHAT-01).
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
  });

  /// Parses the backend thread DTO — camelCase. Participant names are derived
  /// client-side, so they stay null from the wire.
  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
        buyerId: json['buyerId'] as String? ?? json['buyer_id'] as String? ?? '',
        sellerId: json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
        driverId: json['driverId'] as String? ?? json['driver_id'] as String?,
        buyerName: json['buyerName'] as String?,
        sellerName: json['sellerName'] as String?,
        driverName: json['driverName'] as String?,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      );
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

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.type,
    required this.content,
    this.fileUrl,
    required this.sentAt,
    this.readAt,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

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
      );
}
