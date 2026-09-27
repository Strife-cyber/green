import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

/// Admin accounts & roles (ADM-13, design 41) — super-admin only:
/// `GET /admin/admins` lists every admin with its role; a super-admin can add
/// an admin (`POST /admin/admins`) or change a role
/// (`PATCH /admin/admins/:userId/role`). Other roles see a read-only notice.
final _adminsProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(adminRepositoryProvider).admins(),
);

class AdminAdminsScreen extends ConsumerWidget {
  const AdminAdminsScreen({super.key});

  bool _isSuperAdmin(WidgetRef ref) =>
      ref.read(authControllerProvider).valueOrNull?.user?.adminRole ==
      AdminRole.superAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final superAdmin = _isSuperAdmin(ref);
    final admins = ref.watch(_adminsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.adminsAndRoles),
        actions: [
          if (superAdmin)
            IconButton(
              tooltip: context.t.addAdmin,
              icon: const Icon(Icons.person_add_alt),
              onPressed: () => _addAdmin(context, ref),
            ),
        ],
      ),
      body: superAdmin
          ? RefreshableAsyncView<List<User>>(
              value: admins,
              onRefresh: () async => ref.invalidate(_adminsProvider),
              onRetry: () => ref.invalidate(_adminsProvider),
              empty: EmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: context.t.noAdminsTitle,
                message: context.t.noAdminsBody,
              ),
              builder: (list) => ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _AdminTile(admin: list[index]),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.lock_outline,
                  title: context.t.superAdminOnly,
                  message: context.t.superAdminOnlyBody,
                ),
              ),
            ),
    );
  }

  Future<void> _addAdmin(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddAdminDialog(),
    );
    if (created == true && context.mounted) {
      ref.invalidate(_adminsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.adminCreated)),
      );
    }
  }
}

class _AdminTile extends ConsumerWidget {
  final User admin;

  const _AdminTile({required this.admin});

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    AdminRole? role,
  ) async {
    if (role == null || role == admin.adminRole) return;
    try {
      await ref.read(adminRepositoryProvider).updateAdminRole(admin.id, role);
      ref.invalidate(_adminsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e, context))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: UserAvatar(name: admin.fullName),
        title: Text(admin.fullName, style: theme.textTheme.titleSmall),
        subtitle: Text(admin.email,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.tanDark)),
        trailing: DropdownButton<AdminRole>(
          value: admin.adminRole ?? AdminRole.support,
          underline: const SizedBox.shrink(),
          items: [
            for (final role in AdminRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: (role) => _changeRole(context, ref, role),
        ),
      ),
    );
  }
}

class _AddAdminDialog extends ConsumerStatefulWidget {
  const _AddAdminDialog();

  @override
  ConsumerState<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<_AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  AdminRole _role = AdminRole.support;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).createAdmin(
            CreateAdminInput(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              role: _role,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e, context))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.addAdmin),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormTextField(
                controller: _firstName,
                label: t.firstName,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.required : null,
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _lastName,
                label: t.lastName,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.required : null,
              ),
              const SizedBox(height: 12),
              FormTextField(
                controller: _email,
                label: t.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? t.invalidEmail : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminRole>(
                initialValue: _role,
                decoration: InputDecoration(labelText: t.role),
                items: [
                  for (final role in AdminRole.values)
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: (role) =>
                    setState(() => _role = role ?? AdminRole.support),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(t.addAdmin),
        ),
      ],
    );
  }
}
