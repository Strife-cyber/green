import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/cameroon_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/cameroon.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/form_text_field.dart';
import '../../../shared/widgets/password_strength_bar.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../../../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';

/// Signup entry (AUTH-01/09, design 02–07). `initialRole` comes from the
/// welcome screen's role cards (`/signup?role=…`). Buyers keep the short
/// single-page form; sellers get the 4-step wizard — Step 01 account →
/// 02 farm details → 03 identity → 04 pending (its own screen).
class SignupScreen extends ConsumerStatefulWidget {
  final UserRole? initialRole;

  const SignupScreen({super.key, this.initialRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  late UserRole _role = widget.initialRole ?? UserRole.buyer;

  /// The seller wizard step (1 = account, 2 = farm, 3 = identity). Step 4 is
  /// the pending-approval screen the router lands on after submit.
  int _step = 1;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _farmName = TextEditingController();
  final _farmLocation = TextEditingController();
  final _license = TextEditingController();
  final _farmDescription = TextEditingController();

  String? _region;
  int? _mainCategoryId;
  String? _nationalIdUrl;
  String? _selfieUrl;

  /// Farm coordinates captured by "Use my location" — pushed to the seller
  /// profile during post-signup onboarding (not part of the signup DTO).
  double? _farmLatitude;
  double? _farmLongitude;
  bool _locating = false;

  /// Identity step toggle: the second tile is either a selfie or a photo of
  /// the seller's market space — same upload slot, different guidance.
  bool _selfieIsMarketSpace = false;

  bool _obscure = true;
  bool _agreeTerms = false;
  bool _submitting = false;

  bool get _isSeller => _role == UserRole.seller;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _farmName.dispose();
    _farmLocation.dispose();
    _license.dispose();
    _farmDescription.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final detection = await CameroonLocator.detect();
      if (!mounted) return;
      if (!detection.detected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.locationUnavailable)),
        );
        return;
      }
      setState(() {
        _farmLatitude = detection.latitude;
        _farmLongitude = detection.longitude;
        final placemark = detection.placemark;
        if (placemark != null) {
          final line = CameroonLocator.addressLineFrom(placemark);
          if (line.isNotEmpty) _farmLocation.text = line;
          final region = CameroonLocator.regionFromPlacemark(placemark);
          if (region != null) _region = region;
        }
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Validates just the rendered step's fields, then moves forward; the final
  /// step submits.
  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    // The category chips aren't FormFields — validate the selection by hand.
    if (_isSeller && _step == 2 && _mainCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.farmCategoriesRequired)),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.termsRequired)),
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
        farmName: _isSeller ? _farmName.text.trim() : null,
        mainCategoryId: _isSeller ? _mainCategoryId : null,
        businessLicense: _isSeller && _license.text.trim().isNotEmpty
            ? _license.text.trim()
            : null,
        farmDescription:
            _isSeller && _farmDescription.text.trim().isNotEmpty
                ? _farmDescription.text.trim()
                : null,
        nationalIdUrl: _isSeller ? _nationalIdUrl : null,
        selfieUrl: _isSeller ? _selfieUrl : null,
        farmLatitude: _isSeller ? _farmLatitude : null,
        farmLongitude: _isSeller ? _farmLongitude : null,
      );
      await ref.read(authControllerProvider.notifier).signup(input);
      // The router bounces buyers to their home; sellers land on the
      // pending-approval screen (step 04 of the wizard).
      if (mounted && _isSeller) context.go(AppRoutes.sellerPending);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.signUpFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// "Do this later" on the identity step — skips the photo uploads and goes
  /// straight to account creation; the profile screen can re-upload them.
  void _skipIdentity() => _submit();

  /// Opens a short terms summary dialog from the tappable terms link. In a
  /// real deployment this would load the hosted legal pages; the dialog keeps
  /// the flow self-contained and non-blocking.
  void _showTermsDialog(String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(context.t.termsSummary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.t.ok),
          ),
        ],
      ),
    );
  }

  /// Farm-category chips (design 05): the six seeded backend categories —
  /// Vegetables · Fruits · Grains · Dairy · Organic · Mixed — rendered as a
  /// single-select chip group so `mainCategoryId` always references a real id.
  Widget _categoryChips(AsyncValue<List<Category>> categories) =>
      categories.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Text(
          context.t.categoriesUnavailable,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.tanDark),
        ),
        data: (list) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in list)
              ChoiceChip(
                label: Text(c.name),
                selected: _mainCategoryId == c.id,
                onSelected: _submitting
                    ? null
                    : (selected) =>
                        setState(() => _mainCategoryId = selected ? c.id : null),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Real categories from the backend — never mock IDs (a hardcoded
    // `mainCategoryId` that doesn't exist in the DB fails signup with 409).
    final categories = ref.watch(categoriesProvider);
    final t = context.t;
    return AuthShell(
      title: _isSeller ? t.signupSellerTitle : t.createAccount,
      subtitle: _isSeller ? t.signupSellerSubtitle : t.signupBuyerSubtitle,
      child: Form(
        key: _formKey,
        child: _isSeller
            ? _buildSellerWizard(categories)
            : _buildBuyerForm(categories),
      ),
    );
  }

  // ------------------------------------------------------------------ buyer

  Widget _buildBuyerForm(AsyncValue<List<Category>> categories) {
    final theme = Theme.of(context);
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<UserRole>(
          segments: [
            ButtonSegment(
                value: UserRole.buyer,
                label: Text(t.roleBuyer),
                icon: const Icon(Icons.shopping_bag_outlined)),
            ButtonSegment(
                value: UserRole.seller,
                label: Text(t.roleSeller),
                icon: const Icon(Icons.storefront_outlined)),
          ],
          selected: {_role},
          onSelectionChanged:
              _submitting ? null : (s) => setState(() => _role = s.first),
        ),
        const SizedBox(height: 20),
        _accountFields(),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _agreeTerms,
          onChanged:
              _submitting ? null : (v) => setState(() => _agreeTerms = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: _TermsRichText(onShowTerms: _showTermsDialog),
        ),
        const SizedBox(height: 8),
        _submitButton(t.createAccount),
        const SizedBox(height: 12),
        _alreadyHaveAccount(theme),
      ],
    );
  }

  // ----------------------------------------------------------------- wizard

  Widget _buildSellerWizard(AsyncValue<List<Category>> categories) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.signupStepOf(step: _step, total: 4),
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.tanDark),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _step / 4,
          color: AppColors.green,
          backgroundColor: AppColors.greenPale,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 20),
        switch (_step) {
          1 => _stepAccount(),
          2 => _stepFarm(categories),
          _ => _stepIdentity(),
        },
        const SizedBox(height: 20),
        Row(
          children: [
            if (_step > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _step--),
                  child: Text(t.back),
                ),
              ),
            if (_step > 1) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _submitting ? null : _next,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _step == 3 ? t.finishSignup : t.continueLabel,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _alreadyHaveAccount(Theme.of(context)),
      ],
    );
  }

  Widget _stepAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _accountFields(),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _agreeTerms,
          onChanged:
              _submitting ? null : (v) => setState(() => _agreeTerms = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: _TermsRichText(onShowTerms: _showTermsDialog),
        ),
      ],
    );
  }

  Widget _stepFarm(AsyncValue<List<Category>> categories) {
    final t = context.t;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormTextField(
          controller: _farmName,
          label: t.farmName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.storefront_outlined),
          validator: (v) => validateRequired(v, t.farmName),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _farmDescription,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t.farmDescription,
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: _farmLocation,
          label: t.farmLocation,
          hintText: t.farmLocationHint,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.place_outlined),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _locating || _submitting ? null : _useMyLocation,
          icon: _locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(t.useMyLocation),
        ),
        const SizedBox(height: 16),
        Text(t.farmCategories, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _categoryChips(categories),
        if (_mainCategoryId == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t.farmCategoriesRequired,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.tanDark)),
          ),
        const SizedBox(height: 16),
        // The design's "attach business licence" tile — licence upload has no
        // storage endpoint, so the field records the licence number instead.
        Card(
          color: AppColors.greenPale,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.businessLicenseTile,
                          style: theme.textTheme.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FormTextField(
                  controller: _license,
                  label: t.businessLicenseNumber,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepIdentity() {
    final t = context.t;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhotoTile(
          icon: Icons.badge_outlined,
          title: t.nationalIdTile,
          subtitle: t.nationalIdHint,
          imagePath: _nationalIdUrl,
          onPicked: (path) => setState(() => _nationalIdUrl = path),
        ),
        const SizedBox(height: 12),
        _PhotoTile(
          icon: _selfieIsMarketSpace
              ? Icons.storefront_outlined
              : Icons.face_outlined,
          title: _selfieIsMarketSpace
              ? t.marketSpaceTile
              : t.selfieTile,
          subtitle: _selfieIsMarketSpace
              ? t.marketSpaceHint
              : t.selfieHint,
          imagePath: _selfieUrl,
          onPicked: (path) => setState(() => _selfieUrl = path),
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(t.selfieOptionSelfie)),
            ButtonSegment(value: true, label: Text(t.selfieOptionMarket)),
          ],
          selected: {_selfieIsMarketSpace},
          onSelectionChanged: _submitting
              ? null
              : (s) => setState(() => _selfieIsMarketSpace = s.first),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: AppColors.tanDark),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.identityAdminOnly,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.tanDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _submitting ? null : _skipIdentity,
            child: Text(t.doThisLater),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- shared

  /// Name/contact/region/password fields — shared by the buyer's single page
  /// and the seller wizard's Step 01.
  Widget _accountFields() {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormTextField(
          controller: _firstName,
          label: t.firstName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline),
          validator: (v) => validateRequired(v, t.firstName),
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: _lastName,
          label: t.lastName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline),
          validator: (v) => validateRequired(v, t.lastName),
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: _email,
          label: t.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.mail_outline),
          validator: validateEmail,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: _phone,
          label: t.phone,
          hintText: '6XX XX XX XX',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: validatePhone,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _region,
          decoration: InputDecoration(
            labelText: t.region,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
          items: [
            for (final region in kCameroonRegions)
              DropdownMenuItem(value: region, child: Text(region)),
          ],
          onChanged: _submitting ? null : (v) => setState(() => _region = v),
          validator: (v) => v == null ? t.selectRegion : null,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: _password,
          label: t.password,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: validatePassword,
          onChanged: (_) => setState(() {}),
        ),
        PasswordStrengthBar(password: _password.text),
        const SizedBox(height: 16),
        FormTextField(
          controller: _confirm,
          label: t.confirmPassword,
          obscureText: true,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.lock_outline),
          validator: (v) => validateConfirmPassword(v, _password.text),
        ),
      ],
    );
  }

  Widget _submitButton(String label) => FilledButton(
        onPressed: _submitting ? null : _submit,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      );

  Widget _alreadyHaveAccount(ThemeData theme) {
    final t = context.t;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(t.alreadyHaveAccount, style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(t.signIn),
        ),
      ],
    );
  }
}

/// A guided photo tile for one identity document (AUTH-09) — picker on the
/// left, label + framing hint on the right, image thumbnail once picked.
class _PhotoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? imagePath;
  final ValueChanged<String> onPicked;

  const _PhotoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = imagePath != null;
    return Card(
      color: picked ? AppColors.greenPale : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            PhotoPicker(imagePath: imagePath, size: 72, onPicked: onPicked),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (picked)
                        const Icon(Icons.check_circle,
                            size: 18, color: AppColors.green),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.tanDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "I agree to the Terms of Service and Privacy Policy" label with the
/// two legal terms rendered as tappable links (each opens [onShowTerms]).
/// Falls back to plain text if the localized sentence can't be split on the
/// terms' own translations.
class _TermsRichText extends ConsumerStatefulWidget {
  final void Function(String title) onShowTerms;

  const _TermsRichText({required this.onShowTerms});

  @override
  ConsumerState<_TermsRichText> createState() => _TermsRichTextState();
}

class _TermsRichTextState extends ConsumerState<_TermsRichText> {
  TapGestureRecognizer? _tosRecognizer;
  TapGestureRecognizer? _ppRecognizer;

  @override
  void dispose() {
    _tosRecognizer?.dispose();
    _ppRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = context.t.agreeTerms;
    final tos = context.t.termsOfService;
    final pp = context.t.privacyPolicy;

    final tosIndex = full.indexOf(tos);
    final ppIndex = full.indexOf(pp);
    if (tosIndex < 0 || ppIndex < 0) {
      // Sentence doesn't embed the term labels — render it as plain text.
      return Text(full, style: theme.textTheme.bodySmall);
    }

    final linkStyle = TextStyle(
      color: AppColors.greenDark,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    _tosRecognizer ??= TapGestureRecognizer()
      ..onTap = () => widget.onShowTerms(tos);
    _ppRecognizer ??= TapGestureRecognizer()
      ..onTap = () => widget.onShowTerms(pp);

    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          TextSpan(text: full.substring(0, tosIndex)),
          TextSpan(text: tos, style: linkStyle, recognizer: _tosRecognizer),
          TextSpan(text: full.substring(tosIndex + tos.length, ppIndex)),
          TextSpan(text: pp, style: linkStyle, recognizer: _ppRecognizer),
          TextSpan(text: full.substring(ppIndex + pp.length)),
        ],
      ),
    );
  }
}
