import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';

/// Design 08 — the post-signup "seller pending approval" screen. Reached right
/// after the 4-step wizard (and again whenever a pending seller opens the app);
/// the checklist keeps expectations set while an admin reviews the documents.
class SellerPendingScreen extends ConsumerWidget {
  const SellerPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 72, color: AppColors.green),
                  const SizedBox(height: 16),
                  Text(
                    t.sellerPendingTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.sellerPendingSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _ChecklistRow(
                              icon: Icons.check_circle,
                              label: t.pendingDocsReceived,
                              done: true),
                          const SizedBox(height: 14),
                          _ChecklistRow(
                              icon: Icons.verified_user_outlined,
                              label: t.pendingAdminReview,
                              done: false),
                          const SizedBox(height: 14),
                          _ChecklistRow(
                              icon: Icons.storefront_outlined,
                              label: t.pendingListingsLive,
                              done: false),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        context.go('${AppRoutes.sellerProducts}/new'),
                    icon: const Icon(Icons.add_business_outlined),
                    label: Text(t.pendingDraftProduct),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    child: Text(t.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _ChecklistRow({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            color: done ? AppColors.green : AppColors.tanDark, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: done ? AppColors.ink : AppColors.tanDark,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
