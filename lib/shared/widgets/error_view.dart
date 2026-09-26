import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/l10n_ext.dart';
import '../../theme/app_colors.dart';

/// Maps a thrown [Object] to a clean, human-readable message — the shared
/// source of truth for error copy across [AsyncView]/[RefreshableAsyncView].
///
/// [ApiException]s are pattern-matched on their typed fields (not string
/// slicing, which used to land mid-way through `status: null`):
/// - network/timeout/unauthorized get fixed, localised copy;
/// - HTTP errors surface the server's own message when present;
/// - anything else falls back to the generic error.
String friendlyErrorMessage(Object error, BuildContext context) {
  if (error is ApiException) {
    switch (error.kind) {
      case ApiErrorKind.network:
        return context.t.errorNoConnection;
      case ApiErrorKind.timeout:
        return context.t.errorTimeout;
      case ApiErrorKind.unauthorized:
        return context.t.errorUnauthorized;
      case ApiErrorKind.forbidden:
      case ApiErrorKind.notFound:
      case ApiErrorKind.conflict:
      case ApiErrorKind.validation:
      case ApiErrorKind.server:
        return error.message.isNotEmpty ? error.message : context.t.errorGeneric;
      case ApiErrorKind.unknown:
        return error.message.isNotEmpty ? error.message : context.t.errorGeneric;
    }
  }
  final text = error.toString().trim();
  return text.isEmpty ? context.t.errorGeneric : text;
}

/// Consistent error state with an optional retry action.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.tanDark),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.t.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
