import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
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
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty) {
      _showError('Enter your email address first.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(_email.text);
      if (mounted) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code sent — check your inbox (demo code: 123456).')),
        );
      }
    } catch (_) {
      if (mounted) _showError('Could not send the code. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verify() async {
    if (_code.text.trim().isEmpty) {
      _showError('Enter the 6-digit code.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithOtp(email: _email.text, code: _code.text);
      // On success the router redirect moves the user to their role home.
    } catch (_) {
      if (mounted) _showError('That code is not valid. Check it and try again.');
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
      subtitle: 'No password needed — we text you a one-time code',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormTextField(
            controller: _email,
            label: 'Email',
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
              label: '6-digit code',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.pin_outlined),
              onChanged: (_) => setState(() {}),
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
                : Text(_codeSent ? 'Verify & log in' : 'Send code'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Back to password sign in'),
          ),
          const SizedBox(height: 4),
          Text(
            'Demo code: 123456',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
          ),
        ],
      ),
    );
  }
}
