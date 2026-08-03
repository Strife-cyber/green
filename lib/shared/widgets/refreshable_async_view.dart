import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_view.dart';

/// Like [AsyncView] but with a pull-to-refresh gesture.
///
/// [onRefresh] is wired to a [RefreshIndicator] around the data, and
/// `skipLoadingOnRefresh` keeps the previous data visible (no spinner flash)
/// while a refresh re-fetches. When [empty] is provided and `T` is an empty
/// `List`, the empty state is rendered inside an always-scrollable viewport so
/// it can still be pulled.
class RefreshableAsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;
  final Widget? empty;
  final Widget? loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const RefreshableAsyncView({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.builder,
    this.empty,
    this.loading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: (data) {
        final isEmpty = empty != null && data is List && (data as List).isEmpty;
        final child = isEmpty ? pullable(empty!) : builder(data);
        return RefreshIndicator(onRefresh: onRefresh, child: child);
      },
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorView(message: errorMessage ?? _friendly(error), onRetry: onRetry),
    );
  }

  /// Wraps [child] in an always-scrollable viewport so a [RefreshIndicator] can
  /// trigger even when the child doesn't scroll (e.g. an [EmptyState]).
  static Widget pullable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }

  String _friendly(Object error) {
    final text = error.toString();
    // Strip the leading 'Exception: ' noise from ApiException.toString.
    return text.contains(': ') ? text.substring(text.indexOf(': ') + 2) : text;
  }
}
