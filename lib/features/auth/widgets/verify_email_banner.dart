import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';

/// D7 browse-only gate mounted above the navigator from `MaterialApp.builder`:
/// while the signed-in user's email is unverified, the child (the whole app)
/// renders below a persistent "verify your email" strip. Browsing stays free;
/// order placement is blocked at checkout, and the strip lifts as soon as the
/// session reports verified.
class VerifyEmailGate extends ConsumerWidget {
  final Widget child;

  const VerifyEmailGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    // The tree shape must stay constant: mounting the banner inside a Column
    // that appears only when unverified reparents the Router's subtree mid-
    // navigation and go_router reverts the redirect-driven route change.
    return Column(
      children: [
        if (user != null && !user.emailVerified)
          const SafeArea(bottom: false, child: VerifyEmailBanner())
        else
          const SizedBox.shrink(),
        Expanded(child: child),
      ],
    );
  }
}

/// The strip itself: resend link (30s cooldown) + a one-shot status check that
/// polls `GET /auth/me` and lifts the banner the moment the backend reports
/// verified.
class VerifyEmailBanner extends ConsumerStatefulWidget {
  const VerifyEmailBanner({super.key});

  @override
  ConsumerState<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<VerifyEmailBanner> {
  static const int _resendCooldownSeconds = 30;

  bool _busy = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend(String email) async {
    if (_cooldown > 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification(email);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t.verifyEmailSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.verifyEmailResendFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    final verified = await ref
        .read(authControllerProvider.notifier)
        .checkEmailVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not verified yet. Check your inbox for the link.'),
        ),
      );
    }
    // Verified → auth state flipped → this banner unmounts itself.
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
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final email = user?.email ?? '';
    final theme = Theme.of(context);
    return Material(
      color: AppColors.orange.withValues(alpha: 0.14),
      child: InkWell(
        onTap: () => context.push(AppRoutes.verifyEmail),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 20,
                color: AppColors.orangeDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t.verifyToOrderHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: (_busy || _cooldown > 0 || email.isEmpty)
                    ? null
                    : () => _resend(email),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.greenDark,
                ),
                child: Text(
                  _cooldown > 0
                      ? context.t.resendInSeconds(seconds: _cooldown)
                      : context.t.resendEmail,
                ),
              ),
              IconButton(
                // No tooltip: this banner lives above the Navigator (mounted
                // from MaterialApp.builder) where no Overlay ancestor exists.
                visualDensity: VisualDensity.compact,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                color: AppColors.greenDark,
                onPressed: _busy ? null : _check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
