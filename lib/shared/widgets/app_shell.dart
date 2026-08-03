import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_bottom_nav_bar.dart';

/// A bottom-navigation tab.
class AppShellTab {
  final String label;
  final IconData icon;
  final int? badge;
  final Widget page;

  const AppShellTab({
    required this.label,
    required this.icon,
    required this.page,
    this.badge,
  });
}

/// Role home shell in the BraidsBook style: a single Scaffold over the tab
/// pages, a floating pill [CustomBottomNavBar], a persisted tab index and
/// PopScope "back → first tab → exit" handling.
///
/// Each tab [AppShellTab.page] is expected to be a self-contained Scaffold
/// that owns its own header (AppBar) — the shell renders no AppBar, so there
/// is never a double header.
class AppShell extends ConsumerStatefulWidget {
  /// Which role's tab index to drive (see `core/router/nav_providers.dart`).
  final StateProvider<int> tabProvider;

  final List<AppShellTab> tabs;

  /// Unique key for persisting the selected tab across restarts (nullable to
  /// opt out).
  final String? persistKey;

  const AppShell({
    super.key,
    required this.tabProvider,
    required this.tabs,
    this.persistKey,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    _restoreIndex();
  }

  Future<void> _restoreIndex() async {
    final key = widget.persistKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('tab.$key');
      if (saved != null) {
        // Clamp in case the persisted index came from an older build with more
        // tabs (e.g. the nav bars were trimmed from 7 → 4).
        ref.read(widget.tabProvider.notifier).state = _clamp(saved);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  int _clamp(int index) =>
      widget.tabs.isEmpty ? 0 : index.clamp(0, widget.tabs.length - 1).toInt();

  void _onTap(int index) {
    ref.read(widget.tabProvider.notifier).state = index;
    final key = widget.persistKey;
    if (key == null) return;
    try {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setInt('tab.$key', index),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _clamp(ref.watch(widget.tabProvider));
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && index != 0) {
          ref.read(widget.tabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        // Content extends behind the (transparent) nav slot so the floating
        // pill sits over the page, and the tab pages' scrollables carry bottom
        // padding to keep the last items reachable above it.
        extendBody: true,
        body: IndexedStack(index: index, children: [for (final t in widget.tabs) t.page]),
        // Fixed-height slot so the floating pill never expands into the body
        // (Align inside the bar fills its constraints) and never covers content.
        bottomNavigationBar: Container(
          height: 80,
          color: Colors.transparent,
          child: CustomBottomNavBar(
            currentIndex: index,
            items: [
              for (final t in widget.tabs)
                CustomNavItemData(icon: t.icon, label: t.label, badge: t.badge),
            ],
            onTap: _onTap,
          ),
        ),
      ),
    );
  }
}
