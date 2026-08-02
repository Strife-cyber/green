import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_controller.dart';
import '../../l10n/l10n.dart';

/// English / Français toggle. Persists the choice via [LocaleController].
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return SegmentedButton<AppLocale>(
      segments: const [
        ButtonSegment(value: AppLocale.en, label: Text('English'), icon: Icon(Icons.language)),
        ButtonSegment(value: AppLocale.fr, label: Text('Français'), icon: Icon(Icons.language)),
      ],
      selected: {locale},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(localeControllerProvider.notifier).setLocale(selection.first),
    );
  }
}
