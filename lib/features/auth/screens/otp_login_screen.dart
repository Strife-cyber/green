import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

/// Passwordless login by email OTP (AUTH-10): enter your email, receive a
/// one-time code, then verify. On success the router redirect moves the user
/// to their role home.
class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  /// How long the OTP stays valid for (matches the backend's typical expiry).
  static const int _codeExpiryMinutes = 10;

  /// Cooldown between resends, in seconds.
  static const int _resendCooldownSeconds = 30;

  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _submitting = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty) {
      _showError(context.t.enterEmailFirst);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(_email.text);
      if (mounted) {
        setState(() => _codeSent = true);
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.codeSentCheckInbox)),
        );
      }
    } catch (_) {
      if (mounted) _showError(context.t.couldNotSendCode);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(_email.text);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.codeSentCheckInbox)),
        );
      }
    } catch (_) {
      if (mounted) _showError(context.t.couldNotSendCode);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
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

  Future<void> _verify() async {
    if (_code.text.trim().isEmpty) {
      _showError(context.t.enterOtp);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithOtp(email: _email.text, code: _code.text);
      // On success the router redirect moves the user to their role home.
    } catch (_) {
      if (mounted) _showError(context.t.invalidOtpCode);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthShell(
      title: 'Log in with a code',
      subtitle: context.t.otpSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormTextField(
            controller: _email,
            label: context.t.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.mail_outline),
            validator: validateEmail,
            onChanged: (_) => setState(() {}),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 16),
            FormTextField(
              controller: _code,
              label: context.t.enterOtp,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.pin_outlined),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) {
                if (_code.text.trim().length == 6) _verify();
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.t.codeExpiresIn(minutes: _codeExpiryMinutes),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 8),
            // Resend with a countdown so the flow is never a dead end.
            _resending
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _cooldown > 0 ? null : _resend,
                    child: Text(
                      _cooldown > 0
                          ? context.t.resendInSeconds(seconds: _cooldown)
                          : context.t.resendCode,
                    ),
                  ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitting
                ? null
                : _codeSent ? _verify : _sendCode,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(_codeSent ? context.t.verifyAndLogin : context.t.sendCode),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(context.t.backToPasswordSignIn),
          ),
        ],
      ),
    );
  }
}
