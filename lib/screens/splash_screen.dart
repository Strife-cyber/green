import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';

/// Brand splash screen: the logo + wordmark fade in on the cream canvas, hold
/// briefly, zoom out — then the router takes over via [GoRouter.of(context).go]
/// (no raw `Navigator` calls, so the home route always sits at the root and
/// headers never show a spurious back arrow).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    Future.delayed(const Duration(milliseconds: 2400), _zoomOut);
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _zoomOut() async {
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    context.go(user == null ? AppRoutes.login : AppRoutes.homeFor(user.role));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.18)
              .animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn)),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0)
                .animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn)),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0)
                    .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOut)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The logo blends into the cream background seamlessly.
                    Image.asset('assets/logo.png', width: 160, height: 160),
                    const SizedBox(height: 8),
                    Text(
                      context.t.appTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'FRESH · LOCAL · NATURAL',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.tanDark,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
