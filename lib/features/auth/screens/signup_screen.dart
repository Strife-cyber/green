import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/cameroon.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/password_strength_bar.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  UserRole _role = UserRole.buyer;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _farmName = TextEditingController();
  final _license = TextEditingController();
  final _farmDescription = TextEditingController();

  String? _region;
  int? _mainCategoryId;
  String? _nationalIdUrl;
  String? _selfieUrl;
  bool _obscure = true;
  bool _agreeTerms = false;
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _farmName.dispose();
    _license.dispose();
    _farmDescription.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final input = SignupInput(
        role: _role,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        region: _region ?? '',
        password: _password.text,
        farmName: _role == UserRole.seller ? _farmName.text.trim() : null,
        mainCategoryId: _role == UserRole.seller ? _mainCategoryId : null,
        businessLicense: _role == UserRole.seller && _license.text.trim().isNotEmpty
            ? _license.text.trim()
            : null,
        farmDescription:
            _role == UserRole.seller && _farmDescription.text.trim().isNotEmpty
                ? _farmDescription.text.trim()
                : null,
        nationalIdUrl: _role == UserRole.seller ? _nationalIdUrl : null,
        selfieUrl: _role == UserRole.seller ? _selfieUrl : null,
        // Farm coordinates are captured later; the region dropdown stands in
        // for location at sign-up (AUTH-09).
      );
      await ref.read(authControllerProvider.notifier).signup(input);
      // Router redirect takes the new user to their role home.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up failed. Please try again.')),
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
      title: 'Create account',
      subtitle: 'Join the farm-to-table marketplace',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(value: UserRole.buyer, label: Text('Buyer'), icon: Icon(Icons.shopping_bag_outlined)),
                  ButtonSegment(value: UserRole.seller, label: Text('Seller'), icon: Icon(Icons.storefront_outlined)),
                ],
                selected: {_role},
                onSelectionChanged: _submitting
                    ? null
                    : (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 20),
              FormTextField(
                controller: _firstName,
                label: 'First name',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => validateRequired(v, 'First name'),
              ),
              const SizedBox(height: 16),
              FormTextField(
                controller: _lastName,
                label: 'Last name',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => validateRequired(v, 'Last name'),
              ),
              const SizedBox(height: 16),
              FormTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.mail_outline),
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              FormTextField(
                controller: _phone,
                label: 'Phone',
                hintText: '6XX XX XX XX',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: validatePhone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _region,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: [
                  for (final region in kCameroonRegions)
                    DropdownMenuItem(value: region, child: Text(region)),
                ],
                onChanged: _submitting ? null : (v) => setState(() => _region = v),
                validator: (v) => v == null ? 'Select your region.' : null,
              ),
              if (_role == UserRole.seller) ...[
                const SizedBox(height: 16),
                FormTextField(
                  controller: _farmName,
                  label: 'Farm / business name',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  validator: (v) => validateRequired(v, 'Farm name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _mainCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Main product category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final c in MockData.categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: _submitting ? null : (v) => setState(() => _mainCategoryId = v),
                  validator: (v) => v == null ? 'Choose a category.' : null,
                ),
                const SizedBox(height: 16),
                FormTextField(
                  controller: _license,
                  label: 'Business license (optional)',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _farmDescription,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Farm description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Identity verification', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'These documents are reviewed by our team before your farm goes live.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                ),
                const SizedBox(height: 12),
                _IdentityRow(
                  label: 'National ID card',
                  imagePath: _nationalIdUrl,
                  onPicked: (path) => setState(() => _nationalIdUrl = path),
                ),
                const SizedBox(height: 8),
                _IdentityRow(
                  label: 'Selfie of you or your market space',
                  imagePath: _selfieUrl,
                  onPicked: (path) => setState(() => _selfieUrl = path),
                ),
              ],
              const SizedBox(height: 16),
              FormTextField(
                controller: _password,
                label: 'Password',
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
                label: 'Confirm password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (v) => validateConfirmPassword(v, _password.text),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _agreeTerms,
                onChanged: _submitting ? null : (v) => setState(() => _agreeTerms = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('I agree to the Terms of Service and Privacy Policy',
                    style: theme.textTheme.bodySmall),
              ),
              const SizedBox(height: 8),
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
                    : const Text('Create account'),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Already have an account?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled [PhotoPicker] for one seller identity document (AUTH-09).
class _IdentityRow extends StatelessWidget {
  final String label;
  final String? imagePath;
  final ValueChanged<String> onPicked;

  const _IdentityRow({
    required this.label,
    required this.imagePath,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        PhotoPicker(imagePath: imagePath, size: 72, onPicked: onPicked),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
