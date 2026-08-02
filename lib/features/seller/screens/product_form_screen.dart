import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../controllers/product_form_controller.dart';

/// Categories for the product form dropdown (BUY-03).
final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.watch(categoryRepositoryProvider).list());

/// Create (`id == null`) or edit (`id != null`) a product (SELL-01).
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const ProductFormScreen({super.key, this.id});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  int? _categoryId;
  String? _imagePath;
  bool _prefilled = false;
  bool _submitting = false;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    // Prefill once the existing product loads (edit mode only).
    ref.listen(productFormControllerProvider(widget.id), (_, next) {
      final product = next.valueOrNull;
      if (product == null || _prefilled) return;
      _name.text = product.name;
      _description.text = product.description ?? '';
      _price.text = '${product.pricePerKg}';
      _quantity.text = _formatQuantity(product.quantityKg);
      _categoryId = product.categoryId;
      _prefilled = true;
    });
  }

  String _formatQuantity(double kg) => kg == kg.roundToDouble() ? '${kg.toInt()}' : '$kg';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(productFormControllerProvider(widget.id).notifier).submit(
            id: widget.id,
            input: CreateProductInput(
              name: _name.text.trim(),
              description: _description.text.trim().isEmpty ? null : _description.text.trim(),
              categoryId: _categoryId,
              pricePerKg: int.parse(_price.text.trim()),
              quantityKg: double.parse(_quantity.text.trim()),
              imagePath: _imagePath,
            ),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the product. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(productFormControllerProvider(widget.id));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'New Product')),
      body: AsyncView<Product?>(
        value: existing,
        onRetry: () => ref.invalidate(productFormControllerProvider(widget.id)),
        builder: (_) => categories.when(
          data: _buildForm,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: 'Could not load categories.',
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<Category> categories) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: PhotoPicker(
              imagePath: _imagePath,
              onPicked: (path) => setState(() => _imagePath = path),
            ),
          ),
          const SizedBox(height: 20),
          FormTextField(
            controller: _name,
            label: 'Product name',
            textInputAction: TextInputAction.next,
            validator: (v) => validateRequired(v, 'Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Choose a category.' : null,
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _price,
            label: 'Price per kg (FCFA)',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.attach_money),
            validator: _validatePrice,
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _quantity,
            label: 'Quantity (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.scale_outlined),
            validator: _validateQuantity,
          ),
          const SizedBox(height: 24),
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
                : Text(_isEditing ? 'Save changes' : 'Add product'),
          ),
        ],
      ),
    );
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid price.';
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid quantity.';
    return null;
  }
}
