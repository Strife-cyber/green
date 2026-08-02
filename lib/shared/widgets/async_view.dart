import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_view.dart';

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
      error: (error, _) => ErrorView(message: errorMessage ?? _friendly(error), onRetry: onRetry),
    );
  }

  String _friendly(Object error) {
    final text = error.toString();
    // Strip the leading 'Exception: ' noise from ApiException.tooString.
    return text.contains(': ') ? text.substring(text.indexOf(': ') + 2) : text;
  }
}
