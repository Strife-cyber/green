import 'package:animated_splash_themes/animated_splash_themes.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'auth_gate.dart';

/// Brand splash screen.
///
/// Uses the [`animated_splash_themes`] `expand` style — an X-style zoom of the
/// logo + wordmark on the logo's own cream canvas — then hands off to
/// [AuthGate], which routes the user to login or their role home.
///
/// The wordmark colour comes from [AnimatedSplashScreen.accentColor], which is
/// pinned to the dark leaf green so it stays legible on the cream background.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      appName: 'Trendy Green',
      appSubtitle: 'FRESH · LOCAL · NATURAL',
      iconPath: 'assets/logo.png',
      theme: SplashStyle.expand,
      nextScreen: const AuthGate(),
      duration: const Duration(milliseconds: 2800),
      transitionDuration: const Duration(milliseconds: 900),
      // Solid cream so the logo (cream canvas) blends in seamlessly.
      backgroundColors: const [AppColors.background, AppColors.background],
      accentColor: AppColors.greenDark,
    );
  }
}
