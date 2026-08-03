import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import 'language_selector.dart';

/// AppBar action that opens a bottom sheet with the English/Français switch —
/// one tap from any role home.
class LanguageAction extends ConsumerWidget {
  const LanguageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.translate),
      tooltip: context.t.language,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.language,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const LanguageSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
