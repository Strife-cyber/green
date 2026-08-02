import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

/// Post-signup verification prompt (AUTH-03). Unverified accounts may browse
/// but not order (D7); this screen tells them to confirm their email.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;

    return AuthShell(
      title: 'Verify your email',
      subtitle: 'Almost there — one more step',
      child: Column(
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.orange),
          const SizedBox(height: 16),
          Text(
            'We sent a verification link to',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'your email address',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'You can browse while you wait, but you will need to verify before placing orders.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              // Resend — backend not live yet (AUTH-03 email channel).
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification email sent.')),
              );
            },
            child: const Text('Resend email'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
