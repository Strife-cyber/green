import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

/// Post-signup verification prompt (AUTH-03). Unverified accounts may browse
/// but not order (D7); this screen tells them to confirm their email, lets
/// them resend the link (with a cooldown) and re-check their status once
/// they have clicked it.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  /// Cooldown between verification-email resends, in seconds.
  static const int _resendCooldownSeconds = 30;

  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Deep link from the verification email (/verify-email?token=…): consume
    // the token once, then poll the status so the gate lifts on its own.
    final token = GoRouterState.of(context).uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      unawaited(_verifyFromLink(token));
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend(String email) async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification(email);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.verifyEmailSent)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.verifyEmailResendFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyFromLink(String token) async {
    try {
      await ref.read(authControllerProvider.notifier).verifyEmailToken(token);
      if (!mounted) return;
      final verified =
          await ref.read(authControllerProvider.notifier).checkEmailVerification();
      if (!mounted) return;
      if (verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your email is verified — welcome!')),
        );
        context.go(
          AppRoutes.homeFor(ref.read(authControllerProvider).valueOrNull!.user!.role),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This verification link is invalid or has expired.'),
          ),
        );
      }
    }
  }

  /// One-shot `GET /auth/me` poll per tap — no provider invalidate, so the
  /// router never bounces through splash mid-check (that was the old
  /// check-status loop).
  Future<void> _checkStatus() async {
    setState(() => _resending = true);
    final verified =
        await ref.read(authControllerProvider.notifier).checkEmailVerification();
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verified
              ? 'Your email is verified — welcome!'
              : 'Not verified yet. Check your inbox for the link.',
        ),
      ),
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) timer.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final email = user?.email;

    return AuthShell(
      title: context.t.verifyEmailTitle,
      subtitle: context.t.verifyEmailSubtitle,
      child: Column(
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.orange),
          const SizedBox(height: 16),
          Text(
            context.t.verificationLinkSentTo,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            email ?? 'your email address',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            context.t.verifyToOrderHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
          ),
          const SizedBox(height: 24),
          if (email != null && email.isNotEmpty)
            OutlinedButton(
              onPressed: _resending || _cooldown > 0 ? null : () => _resend(email),
              child: Text(
                _cooldown > 0
                    ? context.t.resendInSeconds(seconds: _cooldown)
                    : context.t.resendEmail,
              ),
            )
          else
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to sign in'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resending ? null : _checkStatus,
            child: Text(context.t.checkVerificationStatus),
          ),
          const SizedBox(height: 4),
          if (user != null)
            TextButton(
              onPressed: () => context.go(AppRoutes.homeFor(user.role)),
              child: const Text('Continue browsing'),
            )
          else
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to sign in'),
            ),
        ],
      ),
    );
  }
}
