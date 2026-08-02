import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../theme/app_colors.dart';
import '../controllers/address_controller.dart';

/// Saved delivery addresses (BUY-08): list, add, edit, delete and set-default.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressControllerProvider);
    final controller = ref.read(addressControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: AsyncView<List<Address>>(
        value: addresses,
        onRetry: () => ref.invalidate(addressControllerProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add an address to speed up checkout.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = items[index];
              return _AddressTile(
                address: address,
                onEdit: () => _showForm(context, controller, address: address),
                onDelete: () => _confirmDelete(context, controller, address),
                onSetDefault: address.isDefault
                    ? null
                    : () => controller.setDefault(address.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    AddressController controller, {
    Address? address,
  }) async {
    final input = await showDialog<CreateAddressInput>(
      context: context,
      builder: (context) => _AddressFormDialog(address: address),
    );
    if (input == null) return;
    if (address == null) {
      await controller.add(input);
    } else {
      await controller.edit(address.id, input);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AddressController controller,
    Address address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(address.id);
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const _AddressTile({
    required this.address,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: theme.textTheme.titleSmall),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greenContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Default',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.recipientName} · ${address.phone}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${address.region} — ${address.addressLine}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: address.isDefault ? 'Default address' : 'Set as default',
              icon: Icon(
                Icons.check_circle_outline,
                color: address.isDefault ? AppColors.green : AppColors.tan,
              ),
              onPressed: onSetDefault,
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormDialog extends ConsumerStatefulWidget {
  final Address? address;

  const _AddressFormDialog({this.address});

  @override
  ConsumerState<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends ConsumerState<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.address?.label ?? '');
  late final _recipient =
      TextEditingController(text: widget.address?.recipientName ?? '');
  late final _phone = TextEditingController(text: widget.address?.phone ?? '');
  late final _region = TextEditingController(text: widget.address?.region ?? '');
  late final _line =
      TextEditingController(text: widget.address?.addressLine ?? '');

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _region.dispose();
    _line.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateAddressInput(
        label: _label.text.trim(),
        recipientName: _recipient.text.trim(),
        phone: _phone.text.trim(),
        region: _region.text.trim(),
        addressLine: _line.text.trim(),
        isDefault: widget.address?.isDefault ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.address == null ? 'Add address' : 'Edit address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormTextField(
                controller: _label,
                label: 'Label',
                hintText: 'e.g. Home',
                validator: (v) => validateRequired(v, 'Label'),
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _recipient,
                label: 'Recipient name',
                validator: (v) => validateRequired(v, 'Recipient name'),
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _phone,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _region,
                label: 'Region',
                hintText: 'e.g. Centre',
                validator: (v) => validateRequired(v, 'Region'),
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _line,
                label: 'Address',
                hintText: 'e.g. Bastos, Yaoundé',
                validator: (v) => validateRequired(v, 'Address'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
