import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';

/// Category management (ADM-16): create, rename and delete the product
/// categories sellers pick at sign-up. Reachable from the admin overview's
/// quick actions; only users with the ADMIN role can mutate.
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'Add category', label: 'Category name');
    if (!context.mounted) return;
    if (name == null || name.trim().isEmpty) return;
    await _run(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).createCategory(name.trim()),
      success: 'Category added',
    );
  }

  Future<void> _renameCategory(BuildContext context, WidgetRef ref, Category category) async {
    final name = await _promptName(
      context,
      title: 'Rename category',
      label: 'Category name',
      initial: category.name,
    );
    if (!context.mounted) return;
    if (name == null || name.trim().isEmpty) return;
    await _run(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).renameCategory(category.id, name.trim()),
      success: 'Category renamed',
    );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '"${category.name}" will be removed. Categories still used by '
          'products or sellers cannot be deleted.',
        ),
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
    if (!context.mounted) return;
    if (confirmed != true) return;
    await _run(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).deleteCategory(category.id),
      success: 'Category deleted',
    );
  }

  /// Runs a mutation, refreshes the shared category list and reports the
  /// outcome (the backend's own message surfaces for 409 duplicate/referenced).
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      ref.invalidate(categoriesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong.')),
        );
      }
    }
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    required String label,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: RefreshableAsyncView<List<Category>>(
        value: categories,
        onRefresh: () async => ref.invalidate(categoriesProvider),
        onRetry: () => ref.invalidate(categoriesProvider),
        empty: const EmptyState(
          icon: Icons.category_outlined,
          title: 'No categories',
          message: 'Add the first category to get sellers started.',
        ),
        builder: (list) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = list[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Rename',
                      onPressed: () => _renameCategory(context, ref, category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _deleteCategory(context, ref, category),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
