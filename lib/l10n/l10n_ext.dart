import 'package:flutter/widgets.dart';

import 'generated/strings.g.dart';

/// Shortcut for accessing the current slang [Translations] instance.
///
/// Usage: `context.t.navHome` — automatically rebuilds on locale change
/// (requires the app root to be wrapped in [TranslationProvider]).
extension L10nContext on BuildContext {
  Translations get t => Translations.of(this);
}
