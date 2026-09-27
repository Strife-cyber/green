import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';

/// Design 01 — the standalone Welcome gate. Picks the signup path (buyer vs.
/// seller) or sends returning users to login. Logged-in users never reach it
/// (the router bounces them to their role home).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset('assets/logo.png', width: 132, height: 132),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.appTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    icon: Icons.shopping_basket_outlined,
                    title: t.welcomeBuyerTitle,
                    subtitle: t.welcomeBuyerSubtitle,
                    onTap: () => context.go('${AppRoutes.signup}?role=buyer'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.storefront_outlined,
                    title: t.welcomeSellerTitle,
                    subtitle: t.welcomeSellerSubtitle,
                    onTap: () => context.go('${AppRoutes.signup}?role=seller'),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t.welcomeReturning,
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(t.signIn),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tappable role card on the welcome screen.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.greenPale,
                child: Icon(icon, color: AppColors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.tanDark)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.tanDark),
            ],
          ),
        ),
      ),
    );
  }
}
