import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/password_strength_bar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: _token.text,
            newPassword: _password.text,
          );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset failed. The link may be invalid or expired.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthShell(
      title: 'Choose a new password',
      child: _done
          ? Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 56, color: AppColors.green),
                const SizedBox(height: 16),
                Text('Password updated', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'You can now sign in with your new password.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Sign in'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormTextField(
                    controller: _token,
                    label: 'Reset token',
                    hintText: 'Paste the link token from your email',
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    validator: (v) => validateRequired(v, 'Token'),
                  ),
                  const SizedBox(height: 16),
                  FormTextField(
                    controller: _password,
                    label: 'New password',
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: validatePassword,
                    onChanged: (_) => setState(() {}),
                  ),
                  PasswordStrengthBar(password: _password.text),
                  const SizedBox(height: 16),
                  FormTextField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (v) => validateConfirmPassword(v, _password.text),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
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
                        : const Text('Update password'),
                  ),
                ],
              ),
            ),
    );
  }
}
