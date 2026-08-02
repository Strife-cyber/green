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
      if (saved != null) ref.read(widget.tabProvider.notifier).state = saved;
    } catch (_) {
      // Best-effort.
    }
  }

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
    final index = ref.watch(widget.tabProvider);
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && index != 0) {
          ref.read(widget.tabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: index, children: [for (final t in widget.tabs) t.page]),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: index,
          items: [
            for (final t in widget.tabs)
              CustomNavItemData(icon: t.icon, label: t.label, badge: t.badge),
          ],
          onTap: _onTap,
        ),
      ),
    );
  }
}
