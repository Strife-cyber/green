// End-to-end smoke tests: splash → login/signup → role home, plus the buyer
// browse flow (product grid → detail).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:green/app.dart';
import 'package:green/core/storage/token_storage.dart';
import 'package:green/data/repositories/providers.dart';
import 'package:green/features/buyer/screens/buyer_home_screen.dart';
import 'package:green/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:green/shared/widgets/product_card.dart';

import 'helpers/test_token_storage.dart';

void main() {
  testWidgets('splash → login → buyer home', (WidgetTester tester) async {
    final storage = InMemoryTokenStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          // Keep using the in-memory mocks — no real network in tests.
          useMocksProvider.overrideWithValue(true),
        ],
        child: const GreenApp(),
      ),
    );

    // The brand splash is shown first.
    expect(find.text('Trendy Green'), findsOneWidget);

    // Drive the splash animation + fade transition frame-by-frame.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    // Land on the login screen (not authenticated).
    expect(find.text('Welcome back'), findsOneWidget);

    // Sign in as the demo buyer.
    await tester.enterText(find.byType(TextFormField).at(0), 'buyer@greenish.cm');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Router redirects to the buyer home shell: the feed header + the
    // floating bottom nav are visible.
    expect(find.text('Trendy Green'), findsWidgets);
    expect(find.byType(CustomBottomNavBar), findsOneWidget);

    // The home sits at the root of the router, so its headers never show a
    // spurious back arrow (regression guard for the splash routing fix).
    final homeEl = tester.element(find.byType(BuyerHomeScreen));
    expect(Navigator.of(homeEl).canPop(), isFalse);
  });

  testWidgets('seller sign-up lands on the seller home',
      (WidgetTester tester) async {
    final storage = InMemoryTokenStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          useMocksProvider.overrideWithValue(true),
        ],
        child: const GreenApp(),
      ),
    );

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    // Go to sign-up.
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);

    // Pick Seller.
    await tester.tap(find.text('Seller'));
    await tester.pumpAndSettle();

    // Fill required fields (buyer + seller fields shown for the Seller tab).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jeanne');
    await tester.enterText(fields.at(1), 'Mbarga');
    await tester.enterText(fields.at(2), 'seller-new@greenish.cm');
    await tester.enterText(fields.at(3), '655987654');
    // Region dropdown
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>).first);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centre').last);
    await tester.pumpAndSettle();
    // Farm name
    await tester.ensureVisible(fields.at(4));
    await tester.enterText(fields.at(4), 'Mbarga Organic Farm');
    // Main category dropdown
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>).first);
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organic').last);
    await tester.pumpAndSettle();
    // Password + confirm (license at index 5 is optional and left blank).
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'SellerPass1!');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm password'), 'SellerPass1!');
    // Accept terms
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    // Submit (the button, not the screen title).
    final submit = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // New seller lands on the seller home (Dashboard tab) with the
    // pending-approval banner (AUTH-07).
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.textContaining('pending approval'), findsWidgets);
  });

  testWidgets('buyer browses the product grid and opens a detail screen',
      (WidgetTester tester) async {
    // SharedPreferences is used by the persisted cart.
    SharedPreferences.setMockInitialValues({});

    final storage = InMemoryTokenStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          useMocksProvider.overrideWithValue(true),
        ],
        child: const GreenApp(),
      ),
    );

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'buyer@greenish.cm');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // The buyer home feed renders the seeded products.
    expect(find.byType(ProductCard), findsWidgets);

    // Open the first product → its detail screen shows pricing in FCFA.
    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    // Flush the mock repository latency so no timer is left pending.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('FCFA'), findsWidgets);
  });
}
