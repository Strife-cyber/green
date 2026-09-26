import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_view.dart' show ErrorView, friendlyErrorMessage;

/// Renders an [`AsyncValue`] uniformly: loading spinner → data via [builder],
/// or an [ErrorView]. The single source of truth for loading/error UX.
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
            message: errorMessage ?? friendlyErrorMessage(error, context),
            onRetry: onRetry,
          ),
    );
  }
}
