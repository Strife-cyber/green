import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../theme/app_colors.dart';

/// The splash hands off here (as its `nextScreen`). Once the session restore
/// resolves, [AuthGate] redirects through the router to the login page or the
/// user's role home. It is not a route — it is the post-animation transition.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const _Backdrop(),
      error: (_, _) => const _Backdrop(),
      data: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final user = state.user;
          final destination = user == null ? AppRoutes.login : AppRoutes.homeFor(user.role);
          context.go(destination);
        });
        return const _Backdrop();
      },
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: AppColors.background);
}
