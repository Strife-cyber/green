import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_reports_controller.dart';

/// User reports (profile/chat/order) awaiting admin review (ADM-07, D8).
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const AdminReportsBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Reports" tab of the admin shell.
class AdminReportsBody extends ConsumerWidget {
  const AdminReportsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsControllerProvider);
    return AsyncView<List<Report>>(
      value: reports,
      onRetry: () => ref.invalidate(adminReportsControllerProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No reports',
              message: 'User reports will appear here for review.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ReportCard(report: list[index]),
            ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final Report report;

  const _ReportCard({required this.report});

  Future<void> _apply(BuildContext context, WidgetRef ref, {required bool action}) async {
    await ref
        .read(adminReportsControllerProvider.notifier)
        .applyAction(report.id, action: action);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(action ? 'Report actioned' : 'Report reviewed')));
  }

  String get _targetLabel => switch (report.targetType) {
        ReportTargetType.profile => 'Profile',
        ReportTargetType.chat => 'Chat message',
        ReportTargetType.order => 'Order',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: report.reportedId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.reportedId, style: theme.textTheme.titleMedium),
                      Text('$_targetLabel · ${report.status.name}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.reason,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (report.details != null) ...[
              const SizedBox(height: 4),
              Text(report.details!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _apply(context, ref, action: false),
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _apply(context, ref, action: true),
                    child: const Text('Action'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
