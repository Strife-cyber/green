import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/chat.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';

/// Admin chat-audit threads (`GET /admin/chat/threads`, ADM-12) — read-only
/// oversight list; tapping a thread opens the read-only message view.
final _adminThreadsProvider = FutureProvider.autoDispose<List<ChatThread>>(
  (ref) => ref.watch(adminRepositoryProvider).chatThreads(),
);

class AdminChatThreadsScreen extends ConsumerWidget {
  const AdminChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(_adminThreadsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.chatAuditTitle),
      ),
      body: RefreshableAsyncView<List<ChatThread>>(
        value: threads,
        onRefresh: () async => ref.invalidate(_adminThreadsProvider),
        onRetry: () => ref.invalidate(_adminThreadsProvider),
        empty: EmptyState(
          icon: Icons.forum_outlined,
          title: context.t.noThreadsTitle,
          message: context.t.noThreadsBody,
        ),
        builder: (list) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _ThreadTile(thread: list[index]),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parties = [
      thread.buyerName ?? 'Buyer',
      thread.sellerName ?? 'Seller',
      if (thread.driverName != null) thread.driverName!,
    ].join(' · ');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.greenPale,
          child: Icon(Icons.forum_outlined, color: AppColors.greenDark),
        ),
        title: Text(parties,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          thread.lastMessage?.content ??
              '${context.t.orderPrefix}${orderReference(thread.orderId)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.tanDark),
        onTap: () => context.push(AppRoutes.adminThread(thread.id)),
      ),
    );
  }
}
