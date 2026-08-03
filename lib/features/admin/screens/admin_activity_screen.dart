import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/activity_log.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_activity_controller.dart';

/// Admin activity log — an audit trail of who did what, when (ADM-15).
class AdminActivityScreen extends StatelessWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Activity Log')),
      body: const AdminActivityBody(),
    );
  }
}

/// Reusable list body — also embeddable as an admin shell tab.
class AdminActivityBody extends ConsumerWidget {
  const AdminActivityBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(adminActivityControllerProvider);
    return RefreshableAsyncView<List<ActivityLog>>(
      value: log,
      onRefresh: () => ref.read(adminActivityControllerProvider.notifier).refresh(),
      onRetry: () => ref.invalidate(adminActivityControllerProvider),
      empty: const EmptyState(
        icon: Icons.history,
        title: 'No activity yet',
        message: 'Audit events will appear here.',
      ),
      builder: (list) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _ActivityTile(event: list[index]),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLog event;

  const _ActivityTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: UserAvatar(name: event.actorName),
        title: Text(event.action, style: theme.textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.actorName, style: theme.textTheme.bodyMedium),
            if (event.details != null)
              Text(event.details!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
            const SizedBox(height: 2),
            Text(
              DateFormat('d MMM yyyy · HH:mm').format(event.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tanDark),
            ),
          ],
        ),
        isThreeLine: event.details != null,
      ),
    );
  }
}
