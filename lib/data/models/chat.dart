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

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'] as String,
        orderId: json['order_id'] as String? ?? '',
        buyerId: json['buyer_id'] as String? ?? '',
        sellerId: json['seller_id'] as String? ?? '',
        driverId: json['driver_id'] as String?,
        buyerName: json['buyer_name'] as String?,
        sellerName: json['seller_name'] as String?,
        driverName: json['driver_name'] as String?,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['thread_id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        type: MessageType.fromApi(json['message_type'] as String? ?? 'text'),
        content: json['content'] as String? ?? '',
        fileUrl: json['file_url'] as String?,
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
        readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      );
}
