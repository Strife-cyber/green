import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_chat_controller.dart';

/// Read-only view of a chat thread's messages for admin oversight (ADM-12).
/// Messages render as bubbles with no composer.
class AdminChatScreen extends ConsumerWidget {
  final String threadId;

  const AdminChatScreen({super.key, required this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(adminChatControllerProvider(threadId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Chat')),
      body: AsyncView<List<ChatMessage>>(
        value: messages,
        onRetry: () => ref.invalidate(adminChatControllerProvider(threadId)),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No messages',
                message: 'This thread has no messages yet.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) => _MessageBubble(message: list[index]),
              ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.backgroundElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderId,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 2),
            Text(message.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(
              formatDateTime(message.sentAt),
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark),
            ),
          ],
        ),
      ),
    );
  }
}
