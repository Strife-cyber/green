import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_thread_list_controller.dart';

/// Shared list of chat threads — used by [ChatThreadsScreen] and the driver
/// shell's Chat tab. Each row shows the conversation's counterpart and order.
class ChatThreadList extends ConsumerWidget {
  const ChatThreadList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadListControllerProvider);
    return AsyncView<List<ChatThread>>(
      value: threads,
      onRetry: () => ref.read(chatThreadListControllerProvider.notifier).refresh(),
      builder: (data) {
        if (data.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No conversations yet',
            message: 'When you place an order, a chat thread is created with the seller.',
          );
        }
        final currentUserId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final thread = data[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: UserAvatar(name: _counterpartName(thread, currentUserId)),
                title: Text(
                  _counterpartName(thread, currentUserId),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Order #${thread.orderId}'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.tanDark),
                onTap: () => context.push(AppRoutes.chat(thread.id)),
              ),
            );
          },
        );
      },
    );
  }

  /// The other party in the thread from the current user's perspective.
  String _counterpartName(ChatThread thread, String? currentUserId) {
    if (currentUserId == null || currentUserId == thread.buyerId) {
      return thread.sellerName ?? 'Seller';
    }
    if (currentUserId == thread.sellerId) {
      return thread.buyerName ?? 'Buyer';
    }
    // Driver (or admin) — the person waiting on the delivery.
    return thread.buyerName ?? thread.sellerName ?? 'Chat';
  }
}
