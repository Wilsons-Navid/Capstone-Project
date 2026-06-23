import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethicssec/core/themes/app_theme.dart';

/// Widget + unit tests for the design-system theme: verifies Material 3 is on,
/// the theme-aware EarthColors extension resolves via context, and the AA-safe
/// amber token is distinct from the raw brand amber.
void main() {
  testWidgets('lightTheme exposes EarthColors via context.earth and renders',
      (tester) async {
    EarthColors? earth;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            earth = context.earth;
            return const Scaffold(body: Text('rendered'));
          },
        ),
      ),
    );

    expect(find.text('rendered'), findsOneWidget);
    expect(earth, isNotNull);
    expect(earth!.amberText, equals(AppTheme.amberText));
  });

  test('lightTheme uses Material 3', () {
    expect(AppTheme.lightTheme.useMaterial3, isTrue);
  });

  test('amberText token differs from raw amber (WCAG AA fix)', () {
    // #CC8800 fails AA as text; amberText (#7A5C00) is the AA-safe replacement.
    expect(AppTheme.amberText, isNot(equals(AppTheme.secondaryColor)));
  });
}
