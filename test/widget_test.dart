import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeguard_exam/app.dart';
import 'package:codeguard_exam/core/constants/app_strings.dart';

void main() {
  testWidgets('Welcome screen renders title and Get Started button', (
    WidgetTester tester,
  ) async {
    // Provide a desktop-like surface size for consistent rendering
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build CodeGuardApp
    await tester.pumpWidget(const CodeGuardApp());
    await tester.pumpAndSettle();

    // Verify application name is displayed
    expect(find.text(AppStrings.appName), findsWidgets);

    // Verify Get Started button is present
    final getStartedFinder = find.byKey(const Key('get_started_button'));
    expect(getStartedFinder, findsOneWidget);

    // Tap Get Started button and verify SnackBar triggers
    await tester.tap(getStartedFinder);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
