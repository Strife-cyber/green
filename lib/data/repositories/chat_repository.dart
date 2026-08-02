import '../models/chat.dart';
import '../models/enums.dart';

/// Order-scoped chat threads (CHAT-01..04).
abstract class ChatRepository {
  Future<List<ChatThread>> threads();
  Future<List<ChatMessage>> messages(String threadId);
  Future<ChatMessage> send(String threadId, SendMessageInput input);
  Future<void> markRead(String threadId);
}

class SendMessageInput {
  final String content;
  final MessageType type;
  final String? filePath; // local path for image/voice uploads

  const SendMessageInput({
    required this.content,
    this.type = MessageType.text,
    this.filePath,
  });
}
