import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../widgets/chat_admin_disclosure.dart';
import '../widgets/chat_thread_list.dart';

/// The current user's order conversations (CHAT-01) — with the admin-read
/// disclosure (CHAT-03) pinned on top.
class ChatThreadsScreen extends StatelessWidget {
  const ChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.chatThreadsTitle)),
      body: const Column(
        children: [
          ChatAdminDisclosure(),
          Expanded(child: ChatThreadList()),
        ],
      ),
    );
  }
}
