import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-navigation tab index per role home (the BraidsBook pattern).
/// Each home persists its index in prefs via [AppShell.persistKey].
final buyerTabProvider = StateProvider<int>((ref) => 0);
final sellerTabProvider = StateProvider<int>((ref) => 0);
final driverTabProvider = StateProvider<int>((ref) => 0);
final adminTabProvider = StateProvider<int>((ref) => 0);
