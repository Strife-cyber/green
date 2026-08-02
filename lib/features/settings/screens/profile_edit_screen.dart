import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/cameroon.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_edit_controller.dart';

/// Own-profile editor: editable name/phone/region prefilled from the current
/// authenticated user (AUTH-01, DEL-04).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  String? _region;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _region = user?.region;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(profileEditControllerProvider.notifier).save(
          UpdateProfileInput(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            region: _region,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? context.t.profileUpdated : context.t.saveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileEditControllerProvider).isLoading;
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    return Scaffold(
      appBar: AppBar(title: Text(context.t.editProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FormTextField(
              controller: _firstName,
              label: context.t.firstName,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) => validateRequired(value, context.t.firstName),
            ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _lastName,
              label: context.t.lastName,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) => validateRequired(value, context.t.lastName),
            ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _phone,
              label: context.t.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return validatePhone(value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: InputDecoration(
                labelText: context.t.region,
                prefixIcon: const Icon(Icons.map_outlined),
              ),
              items: [
                for (final region in kCameroonRegions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t.language, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    const LanguageSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(context.t.save),
            ),
          ],
        ),
      ),
    );
  }
}
