import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/cameroon.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../controllers/admin_create_driver_controller.dart';

/// Admin form to create a new delivery driver account (D6).
class AdminCreateDriverScreen extends ConsumerStatefulWidget {
  const AdminCreateDriverScreen({super.key});

  @override
  ConsumerState<AdminCreateDriverScreen> createState() => _AdminCreateDriverScreenState();
}

class _AdminCreateDriverScreenState extends ConsumerState<AdminCreateDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _region;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(adminCreateDriverControllerProvider.notifier).submit(
          CreateDriverInput(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            region: _region!,
          ),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver account created')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not create the driver. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(adminCreateDriverControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('New Driver')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FormTextField(
              controller: _firstName,
              label: 'First name',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) => validateRequired(value, 'First name'),
            ),
            const SizedBox(height: 16),
            FormTextField(
              controller: _lastName,
              label: 'Last name',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) => validateRequired(value, 'Last name'),
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
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: [
                for (final region in kCameroonRegions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
              validator: (value) => value == null ? 'Region is required.' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Create driver'),
            ),
          ],
        ),
      ),
    );
  }
}
