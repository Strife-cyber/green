import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Branded scaffold for auth screens: the logo sits directly on the cream
/// canvas (it blends seamlessly), with a title, optional subtitle and a form
/// card below.
class AuthShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(padding: const EdgeInsets.all(24), child: child),
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
