import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_thread_list_controller.dart';

/// Shared list of chat threads — used by [ChatThreadsScreen] and the driver
/// shell's Chat tab. Each row is a WhatsApp-style entry: counterpart avatar +
/// name, a preview of the last message (with the "delivered ✓✓" glyph and
/// image/voice glyphs for non-text), a relative time, an unread badge and the
/// order-status tag pill.
class ChatThreadList extends ConsumerWidget {
  const ChatThreadList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatThreadListControllerProvider);
    return RefreshableAsyncView<List<ChatThread>>(
      value: threads,
      onRefresh: () => ref.read(chatThreadListControllerProvider.notifier).refresh(),
      onRetry: () => ref.read(chatThreadListControllerProvider.notifier).refresh(),
      empty: EmptyState(
        icon: Icons.chat_bubble_outline,
        title: context.t.chatNoThreads,
        message: context.t.chatNoThreadsHint,
      ),
      builder: (data) {
        final currentUserId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final thread = data[index];
            return _ThreadRow(thread: thread, currentUserId: currentUserId);
          },
        );
      },
    );
  }
}

class _ThreadRow extends ConsumerWidget {
  final ChatThread thread;
  final String? currentUserId;

  const _ThreadRow({required this.thread, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartName = _counterpartName(context);
    final lastMessage = thread.lastMessage;
    final unread = thread.unreadCount;
    return InkWell(
      onTap: () async {
        await context.push(AppRoutes.chat(thread.id));
        if (context.mounted) {
          // Opening the thread marks it read — refresh so the badge clears.
          ref.read(chatThreadListControllerProvider.notifier).refresh();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AvatarWithBadge(name: counterpartName, unread: unread),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          counterpartName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(context),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.tanDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _previewRow(context, lastMessage, unread),
                  if (thread.orderStatus != null) ...[
                    const SizedBox(height: 6),
                    _OrderStatusPill(status: thread.orderStatus!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The other party in the thread from the current user's perspective — the
  /// enriched `counterparty` object when present, else the legacy participants.
  String _counterpartName(BuildContext context) {
    if (thread.counterpartyName != null) return thread.counterpartyName!;
    if (currentUserId == null || currentUserId == thread.buyerId) {
      return thread.sellerName ?? context.t.roleSeller;
    }
    if (currentUserId == thread.sellerId) {
      return thread.buyerName ?? context.t.roleBuyer;
    }
    return thread.buyerName ?? thread.sellerName ?? context.t.chatTitle;
  }

  Widget _previewRow(BuildContext context, ChatThreadLastMessage? lastMessage, int unread) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: unread > 0 ? AppColors.ink : AppColors.tanDark,
      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
    );
    if (lastMessage == null) {
      return Text(
        context.t.chatNoMessages,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final IconData? mediaGlyph = switch (lastMessage.type) {
      MessageType.image => Icons.image_outlined,
      MessageType.voice => Icons.mic_none,
      MessageType.text => null,
    };
    final body = switch (lastMessage.type) {
      MessageType.image => context.t.chatImageGlyph,
      MessageType.voice => context.t.chatVoiceGlyph,
      MessageType.text => lastMessage.content,
    };
    final label = lastMessage.mine ? '${context.t.chatYou}: $body' : body;
    return Row(
      children: [
        // "🗸🗸" glyph on my own last message (WhatsApp-style read tick).
        if (lastMessage.mine) ...[
          Icon(Icons.done_all, size: 14, color: style?.color),
          const SizedBox(width: 2),
        ],
        if (mediaGlyph != null) ...[
          Icon(mediaGlyph, size: 14, color: style?.color),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }

  String _relativeTime(BuildContext context) {
    final time = thread.updatedAt ?? thread.lastMessage?.sentAt ?? thread.createdAt;
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;
    if (days == 0) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (days == 1) return context.t.chatYesterday;
    return formatDate(time);
  }
}

/// Initials avatar with the unread badge pinned to its bottom-right corner.
class _AvatarWithBadge extends StatelessWidget {
  final String name;
  final int unread;

  const _AvatarWithBadge({required this.name, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(name: name, radius: 26),
        if (unread > 0)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small tinted tag showing the order's live status on the thread row.
class _OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.pending => context.t.orderStatusPending,
      OrderStatus.confirmed => context.t.orderStatusConfirmed,
      OrderStatus.shipped => context.t.orderStatusShipped,
      OrderStatus.delivered => context.t.orderStatusDelivered,
      OrderStatus.cancelled => context.t.orderStatusCancelled,
    };
    final color = switch (status) {
      OrderStatus.pending => AppColors.orange,
      OrderStatus.confirmed => const Color(0xFF4A7CBE),
      OrderStatus.shipped => AppColors.green,
      OrderStatus.delivered => AppColors.tanDark,
      OrderStatus.cancelled => const Color(0xFFB3261E),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
