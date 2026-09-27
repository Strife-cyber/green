import 'package:flutter/material.dart';

/// Brand palette extracted from the app logo (`assets/logo.png`).
///
/// The logo sits on a warm cream canvas ([background]). Every app surface
/// reuses that exact tone so the asset blends in seamlessly — no background
/// removal is required anywhere the logo is shown.
///
/// Swatches are the single source of truth for color; the theme in
/// `app_theme.dart` maps them onto Material's `ColorScheme`.
abstract final class AppColors {
  // ---- Logo canvas (cream) -------------------------------------------------
  /// Main app background — identical to the logo's own canvas color.
  static const Color background = Color(0xFFEAD7BD);

  /// Lighter cream for elevated surfaces (cards, dialogs, sheets).
  static const Color backgroundElevated = Color(0xFFF4E6D0);

  /// Warm dark brown for text/ink on the cream background.
  static const Color ink = Color(0xFF3D3124);

  /// Subtle tan used for dividers, outlines and hairline strokes.
  static const Color tan = Color(0xFFC4A67F);

  /// Deeper tan for shadows / pressed-outline states.
  static const Color tanDark = Color(0xFF8A6644);

  // ---- Logo leaf green (primary) -------------------------------------------
  /// Dominant leaf green extracted from the logo foliage (`#2C8434` peak,
  /// `#337C31` average — kept as Material `green.shade800` for a recognisable
  /// Material tonal ramp).
  static const Color green = Color(0xFF2E7D32);

  /// Darker green for pressed states and emphasis.
  static const Color greenDark = Color(0xFF1B5E20);

  /// Soft green used for chips, containers and success surfaces.
  static const Color greenContainer = Color(0xFFA5D6A7);

  /// Softer green tint for selected chips/avatars (between surface and
  /// [greenContainer]).
  static const Color greenPale = Color(0xFFDFF0DC);

  // ---- Logo warm orange (secondary) ----------------------------------------
  /// Warm orange accent extracted from the logo's fruit accent.
  static const Color orange = Color(0xFFF07030);

  /// Deeper orange for pressed states and small text accents.
  static const Color orangeDark = Color(0xFFC94F1F);
}
