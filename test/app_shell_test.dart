import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:green/shared/widgets/app_shell.dart';

void main() {
  testWidgets('AppShell clamps an out-of-range persisted tab index',
      (WidgetTester tester) async {
    // Simulates an index persisted by an older build with more tabs.
    final tabProvider = StateProvider<int>((ref) => 9);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppShell(
            tabProvider: tabProvider,
            tabs: const [
              AppShellTab(label: 'A', icon: Icons.home_outlined, page: Scaffold(body: Center(child: Text('tab A')))),
              AppShellTab(label: 'B', icon: Icons.person_outline, page: Scaffold(body: Center(child: Text('tab B')))),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No IndexedStack assertion — the index is clamped to the last tab.
    expect(find.text('tab B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
