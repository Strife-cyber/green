import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/cameroon_locator.dart';
import '../../../core/utils/cameroon.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/address.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../shared/widgets/address_autocomplete_field.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/address_controller.dart';

/// Saved delivery addresses (BUY-08): list, add, edit, delete and set-default.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressControllerProvider);
    final controller = ref.read(addressControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Saved Addresses')),
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

/// Add / edit address dialog.
///
/// Smart defaults: the recipient's name, phone and region are prefilled from
/// the signed-up account and the label defaults to "Home". The region is a
/// dropdown of the 10 Cameroonian regions, and a "Detect my location" action
/// reverse-geocodes the device position — showing a clear error when the
/// detected country isn't Cameroon (e.g. the device is on a VPN / abroad).
class _AddressFormDialog extends ConsumerStatefulWidget {
  final Address? address;

  const _AddressFormDialog({this.address});

  @override
  ConsumerState<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends ConsumerState<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  String? _region;
  bool _detecting = false;
  String? _detectionMessage;
  bool _detectionError = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    final a = widget.address;
    _label = TextEditingController(text: a?.label ?? 'Home');
    _recipient = TextEditingController(text: a?.recipientName ?? user?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _line = TextEditingController(text: a?.addressLine ?? '');
    _region = a?.region ??
        (user?.region != null && kCameroonRegions.contains(user!.region) ? user.region : null);

    // Ask for location permission up front so the app can help complete the
    // address automatically (the OS dialog appears once the form is shown).
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetect());
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _line.dispose();
    super.dispose();
  }

  Future<void> _autoDetect() async {
    if (!mounted) return;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return; // Manual entry / autocomplete still available.
        }
      }
      await _detect(showDetectFailure: false);
    } catch (_) {
      // Any platform/plugin failure (emulator, web, no geolocator) → the form
      // just stays on manual entry; nothing crashes.
    }
  }

  Future<void> _detect({bool showDetectFailure = true}) async {
    setState(() {
      _detecting = true;
      _detectionMessage = null;
    });
    late final CameroonDetection result;
    try {
      result = await CameroonLocator.detect();
    } catch (_) {
      result = const CameroonDetection();
    }
    if (!mounted) return;
    setState(() {
      _detecting = false;
      if (!result.detected) {
        if (!showDetectFailure) return;
        _detectionError = true;
        _detectionMessage =
            'Could not detect your location (permission or service unavailable). Please enter your address manually.';
      } else if (!result.inCameroon) {
        _detectionError = true;
        _detectionMessage =
            'Address not in Cameroon — please enter an address in Cameroon (pick a region below).';
      } else {
        _detectionError = false;
        final pm = result.placemark!;
        final line = CameroonLocator.addressLineFrom(pm);
        if (line.isNotEmpty) _line.text = line;
        final region = CameroonLocator.regionFromPlacemark(pm);
        if (region != null) _region = region;
        _detectionMessage = 'Location detected in Cameroon — please confirm the details below.';
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateAddressInput(
        label: _label.text.trim(),
        recipientName: _recipient.text.trim(),
        phone: _phone.text.trim(),
        region: _region ?? '',
        addressLine: _line.text.trim(),
        isDefault: widget.address?.isDefault ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      // The form takes ~90% of the screen width (capped so it doesn't get
      // unwieldy on tablets), instead of the default ~280px.
      constraints: BoxConstraints(
        minWidth: 320,
        maxWidth: screenWidth * 0.9 < 480 ? screenWidth * 0.9 : 480,
      ),
      title: Text(widget.address == null ? 'Add address' : 'Edit address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _detecting ? null : _detect,
                  icon: _detecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_detecting ? 'Detecting…' : 'Detect my location'),
                ),
              ),
              if (_detectionMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _detectionError ? Icons.error_outline : Icons.check_circle_outline,
                        size: 18,
                        color: _detectionError ? errorColor : AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _detectionMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _detectionError ? errorColor : AppColors.greenDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                validator: (value) => value == null ? 'Select your region.' : null,
              ),
              const SizedBox(height: 12),
              AddressAutocompleteField(
                controller: _line,
                label: 'Address',
                hintText: 'e.g. Bastos, Yaoundé',
                onSelected: (suggestion) {
                  if (suggestion.region != null && mounted) {
                    setState(() => _region = suggestion.region);
                  }
                },
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
