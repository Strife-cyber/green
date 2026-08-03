import 'package:flutter/material.dart';

import '../widgets/chat_thread_list.dart';

/// The current user's order conversations (CHAT-01).
class ChatThreadsScreen extends StatelessWidget {
  const ChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Chats')),
      body: const ChatThreadList(),
    );
  }
}
