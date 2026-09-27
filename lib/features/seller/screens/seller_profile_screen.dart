import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/location/cameroon_locator.dart';
import '../../../data/models/category.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/seller_profile.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/seller_profile_controller.dart';

/// Seller account profile with links and logout (AUTH-01/07).
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final profile = ref.watch(sellerProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.navProfile),
      ),
      body: AsyncView<SellerProfile>(
        value: profile,
        onRetry: () => ref.invalidate(sellerProfileControllerProvider),
        builder: (sellerProfile) => _ProfileContent(
          user: user,
          profile: sellerProfile,
          onLogout: () => _confirmLogout(context, ref),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be signed out of your seller account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User? user;
  final SellerProfile profile;
  final VoidCallback onLogout;

  const _ProfileContent({required this.user, required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user?.fullName ?? 'Seller';
    final email = user?.email;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                UserAvatar(name: displayName, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(profile.farmName, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
                      if (email != null)
                        Text(email, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
                    ],
                  ),
                ),
                StatusBadge(label: profile.approvalStatus.label, color: _approvalColor(profile.approvalStatus)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Editable farm profile (design 35): name, description, location,
        // category + document uploads — PATCH /seller-profiles/me.
        _FarmDetailsCard(profile: profile),
        const SizedBox(height: 16),
        _DocumentsCard(profile: profile),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _LinkTile(icon: Icons.person_outline, title: context.t.editProfile, onTap: () => context.push(AppRoutes.profile)),
              const Divider(height: 1),
              _LinkTile(icon: Icons.account_balance_wallet_outlined, title: context.t.wallet, onTap: () => context.push(AppRoutes.sellerWallet)),
              const Divider(height: 1),
              _LinkTile(icon: Icons.notifications_outlined, title: context.t.notifications, onTap: () => context.push(AppRoutes.notifications)),
              const Divider(height: 1),
              _LinkTile(icon: Icons.support_agent_outlined, title: context.t.support, onTap: () => context.push(AppRoutes.support)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t.language, style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                const LanguageSelector(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: Text(context.t.logout),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3261E),
            side: const BorderSide(color: Color(0xFFB3261E)),
          ),
        ),
      ],
    );
  }

  Color _approvalColor(SellerApprovalStatus status) => switch (status) {
        SellerApprovalStatus.approved => AppColors.green,
        SellerApprovalStatus.pending => AppColors.orange,
        SellerApprovalStatus.rejected => const Color(0xFFB3261E),
      };
}

/// Farm details (design 35) — shows current values and opens the edit
/// sheet (`PATCH /seller-profiles/me`).
class _FarmDetailsCard extends ConsumerWidget {
  final SellerProfile profile;

  const _FarmDetailsCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final category = categories
        .where((c) => c.id == profile.mainCategoryId)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.farmProfile, style: theme.textTheme.titleSmall),
                ),
                TextButton.icon(
                  onPressed: () => _edit(context, ref, categories),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(t.edit),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(profile.farmName, style: theme.textTheme.titleMedium),
            if (profile.farmDescription != null &&
                profile.farmDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(profile.farmDescription!,
                    style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.tanDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.farmLatitude != null
                        ? '${profile.farmLatitude!.toStringAsFixed(4)}, ${profile.farmLongitude!.toStringAsFixed(4)}'
                        : t.noLocationSet,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: AppColors.tanDark),
                const SizedBox(width: 6),
                Text(
                  category?.name ?? t.uncategorized,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.tanDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _FarmEditDialog(profile: profile, categories: categories),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(sellerProfileControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.profileUpdated)),
      );
    }
  }
}

/// The edit-farm dialog: name, description, main category chips and a
/// "Use my location" button that records the GPS fix (design 35).
class _FarmEditDialog extends ConsumerStatefulWidget {
  final SellerProfile profile;
  final List<Category> categories;

  const _FarmEditDialog({required this.profile, required this.categories});

  @override
  ConsumerState<_FarmEditDialog> createState() => _FarmEditDialogState();
}

class _FarmEditDialogState extends ConsumerState<_FarmEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.farmName);
  late final TextEditingController _description =
      TextEditingController(text: widget.profile.farmDescription ?? '');
  late final TextEditingController _license =
      TextEditingController(text: widget.profile.businessLicense ?? '');
  late int? _categoryId = widget.profile.mainCategoryId;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.profile.farmLatitude;
    _lng = widget.profile.farmLongitude;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final result = await CameroonLocator.detect();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (result.latitude != null) {
        _lat = result.latitude;
        _lng = result.longitude;
      }
    });
    if (result.latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.locationFailed)),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(sellerProfileRepositoryProvider).update(
            farmName: _name.text.trim(),
            mainCategoryId: categoryId,
            farmDescription: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            businessLicense: _license.text.trim().isEmpty
                ? null
                : _license.text.trim(),
            farmLatitude: _lat,
            farmLongitude: _lng,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.editFarmProfile),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormTextField(
                  controller: _name,
                  label: t.farmName,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.required : null,
                ),
                const SizedBox(height: 12),
                FormTextField(
                  controller: _description,
                  label: t.farmDescription,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                FormTextField(
                  controller: _license,
                  label: t.businessLicenseOptional,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final c in widget.categories)
                        ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) =>
                              setState(() => _categoryId = c.id),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(_lat == null
                      ? t.useMyLocation
                      : t.locationSet(
                          lat: _lat!.toStringAsFixed(4),
                          lng: _lng!.toStringAsFixed(4))),
                ),
              ],
            ),
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
          child: Text(t.save),
        ),
      ],
    );
  }
}

/// Identity documents (design 35): National ID + selfie with view links and
/// re-upload affordances — same endpoints as the rejected-profile card.
class _DocumentsCard extends ConsumerStatefulWidget {
  final SellerProfile profile;

  const _DocumentsCard({required this.profile});

  @override
  ConsumerState<_DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends ConsumerState<_DocumentsCard> {
  bool _uploading = false;

  Future<void> _upload(String field) async {
    if (_uploading) return;
    final path = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.uploadIdentityDocument,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 16),
            PhotoPicker(
              size: 140,
              onPicked: (p) => Navigator.of(sheetContext).pop(p),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final repo = ref.read(sellerProfileRepositoryProvider);
      if (field == 'nationalId') {
        await repo.uploadNationalId(path);
      } else {
        await repo.uploadSelfie(path);
      }
      ref.invalidate(sellerProfileControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.documentsUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.uploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _view(String title, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: ImageNetwork(url: url, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.identityDocuments,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _docRow(
              context,
              t.nationalId,
              widget.profile.nationalIdUrl,
              () => _upload('nationalId'),
            ),
            const Divider(height: 16),
            _docRow(
              context,
              t.selfieOrMarket,
              widget.profile.selfieUrl,
              () => _upload('selfie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docRow(
    BuildContext context,
    String label,
    String? url,
    VoidCallback onUpload,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          url == null ? Icons.upload_file : Icons.check_circle_outline,
          size: 20,
          color: url == null ? AppColors.tanDark : AppColors.green,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        if (url != null)
          TextButton(
            onPressed: () => _view(label, url),
            child: Text(context.t.view),
          ),
        TextButton(
          onPressed: _uploading ? null : onUpload,
          child: Text(url == null ? context.t.upload : context.t.reUpload),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greenDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.tanDark),
      onTap: onTap,
    );
  }
}

/// Shown when a seller application was rejected (AUTH-07): lets the seller
/// re-upload identity documents so the profile can be reviewed again. Once
/// both documents are on file, the upload calls `POST /seller-profiles/me/
/// resubmit` to put the profile back in the PENDING queue.
class _RejectedDocumentsCard extends ConsumerStatefulWidget {
  const _RejectedDocumentsCard();

  @override
  ConsumerState<_RejectedDocumentsCard> createState() =>
      _RejectedDocumentsCardState();
}

class _RejectedDocumentsCardState extends ConsumerState<_RejectedDocumentsCard> {
  bool _uploading = false;

  Future<void> _upload(String field) async {
    if (_uploading) return;
    final path = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload identity document',
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 16),
            PhotoPicker(
              size: 140,
              onPicked: (p) => Navigator.of(sheetContext).pop(p),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    final repo = ref.read(sellerProfileRepositoryProvider);
    try {
      if (field == 'nationalId') {
        await repo.uploadNationalId(path);
      } else {
        await repo.uploadSelfie(path);
      }
      await ref.read(sellerProfileControllerProvider.notifier).refresh();
      // Best-effort re-submission: once BOTH documents are on file the profile
      // flips back to PENDING and the rejected banner clears. A 400 while the
      // second document is still missing just means "not yet" — the upload
      // itself succeeded and stays acknowledged.
      try {
        await repo.resubmit();
        await ref.read(sellerProfileControllerProvider.notifier).refresh();
      } catch (_) {
        // One document still missing — wait for the other.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.documentsUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.uploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.backgroundElevated,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.sellerRejectedTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: const Color(0xFFB3261E)),
            ),
            const SizedBox(height: 4),
            Text(
              context.t.sellerRejectedBody,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _upload('nationalId'),
                    icon: const Icon(Icons.badge_outlined),
                    label: Text(context.t.reUploadNationalId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _upload('selfie'),
                    icon: const Icon(Icons.face_outlined),
                    label: Text(context.t.reUploadSelfie),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
