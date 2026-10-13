import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeguard_exam/app.dart';
import 'package:codeguard_exam/core/constants/app_strings.dart';

void main() {
  testWidgets(
    'Full Candidate Onboarding Flow: Validation, Navigation, and Declaration',
    (WidgetTester tester) async {
      // Set desktop screen bounds
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Launch CodeGuardApp and verify Welcome screen
      await tester.pumpWidget(const CodeGuardApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsWidgets);
      final getStartedButton = find.byKey(const Key('get_started_button'));
      expect(getStartedButton, findsOneWidget);

      // 2. Navigate to Candidate Details screen
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingTitle), findsWidgets);
      final nameField = find.byKey(const Key('candidate_name_field'));
      final registerField = find.byKey(const Key('candidate_register_field'));
      final examField = find.byKey(const Key('candidate_exam_field'));
      final proceedButton = find.byKey(const Key('proceed_button'));

      expect(nameField, findsOneWidget);
      expect(registerField, findsOneWidget);
      expect(examField, findsOneWidget);
      expect(proceedButton, findsOneWidget);

      // 3. Test required field validation with empty inputs
      // Clear default exam name to trigger all validators
      await tester.enterText(examField, '');
      await tester.ensureVisible(proceedButton);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorNameRequired), findsOneWidget);
      expect(find.text(AppStrings.errorRegisterRequired), findsOneWidget);
      expect(find.text(AppStrings.errorExamNameRequired), findsOneWidget);

      // 4. Test minimum length validation
      await tester.enterText(nameField, 'A');
      await tester.enterText(registerField, '1');
      await tester.ensureVisible(proceedButton);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorNameTooShort), findsOneWidget);
      expect(find.text(AppStrings.errorRegisterTooShort), findsOneWidget);

      // 5. Fill valid inputs and proceed
      await tester.enterText(nameField, 'Alex Morgan');
      await tester.enterText(registerField, 'CS-2026-8941');
      await tester.enterText(examField, 'Data Structures & Algorithms Final');
      await tester.ensureVisible(proceedButton);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      // 6. Verify Examination Instructions screen
      expect(find.text(AppStrings.instructionsTitle), findsWidgets);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Reg: CS-2026-8941'), findsOneWidget);

      // Verify instruction items
      expect(find.text(AppStrings.ruleDurationTitle), findsOneWidget);
      expect(find.text(AppStrings.ruleFormatTitle), findsOneWidget);
      expect(find.text(AppStrings.ruleSavingTitle), findsOneWidget);
      expect(find.text(AppStrings.ruleSubmissionTitle), findsOneWidget);
      expect(find.text(AppStrings.ruleLifecycleTitle), findsOneWidget);

      // 7. Test declaration checkbox and start button state
      final startExamFinder = find.byKey(const Key('start_examination_button'));
      expect(startExamFinder, findsOneWidget);

      ElevatedButton startButton = tester.widget<ElevatedButton>(startExamFinder);
      expect(
        startButton.onPressed,
        isNull,
        reason: 'Start Examination must be disabled before accepting declaration',
      );

      // Check the declaration checkbox
      final checkboxFinder = find.byKey(const Key('declaration_checkbox'));
      expect(checkboxFinder, findsOneWidget);
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify Start Examination is now enabled
      startButton = tester.widget<ElevatedButton>(startExamFinder);
      expect(
        startButton.onPressed,
        isNotNull,
        reason: 'Start Examination must be enabled once declaration is checked',
      );

      // Tap Start Examination and verify onboarding completion dialog
      await tester.ensureVisible(startExamFinder);
      await tester.tap(startExamFinder);
      await tester.pumpAndSettle();

      expect(find.text('Onboarding Complete!'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      // 8. Test back navigation: Instructions -> Candidate Details -> Welcome
      final instructionsBackFinder = find.byKey(const Key('instructions_back_button'));
      await tester.tap(instructionsBackFinder);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingTitle), findsWidgets);

      final candidateBackFinder = find.byKey(const Key('candidate_back_button'));
      await tester.tap(candidateBackFinder);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsWidgets);
    },
  );
}
