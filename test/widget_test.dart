import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codeguard_exam/app.dart';
import 'package:codeguard_exam/core/constants/app_strings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Complete End-to-End Examination Flow: Onboarding -> Instructions -> Exam Session -> Results',
    (WidgetTester tester) async {
      // Set desktop bounds
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Launch App on Welcome Screen
      await tester.pumpWidget(const CodeGuardApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsWidgets);
      final getStartedButton = find.byKey(const Key('get_started_button'));
      expect(getStartedButton, findsOneWidget);

      // 2. Navigate to Candidate Details Screen
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboardingTitle), findsWidgets);
      final nameField = find.byKey(const Key('candidate_name_field'));
      final registerField = find.byKey(const Key('candidate_register_field'));
      final examField = find.byKey(const Key('candidate_exam_field'));
      final proceedButton = find.byKey(const Key('proceed_button'));

      // Validate required fields
      await tester.enterText(examField, '');
      await tester.ensureVisible(proceedButton);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorNameRequired), findsOneWidget);
      expect(find.text(AppStrings.errorRegisterRequired), findsOneWidget);
      expect(find.text(AppStrings.errorExamNameRequired), findsOneWidget);

      // Enter valid candidate info
      await tester.enterText(nameField, 'Alex Morgan');
      await tester.enterText(registerField, 'CS-2026-8941');
      await tester.enterText(examField, 'Data Structures & Algorithms Final');
      await tester.ensureVisible(proceedButton);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      // 3. Instructions Screen & Declaration
      expect(find.text(AppStrings.instructionsTitle), findsWidgets);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Reg: CS-2026-8941'), findsOneWidget);

      final startExamFinder = find.byKey(const Key('start_examination_button'));
      expect(startExamFinder, findsOneWidget);

      // Check disabled state before declaration
      ElevatedButton startButton = tester.widget<ElevatedButton>(startExamFinder);
      expect(startButton.onPressed, isNull);

      // Check declaration
      final checkboxFinder = find.byKey(const Key('declaration_checkbox'));
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      startButton = tester.widget<ElevatedButton>(startExamFinder);
      expect(startButton.onPressed, isNotNull);

      // 4. Start Examination
      await tester.ensureVisible(startExamFinder);
      await tester.tap(startExamFinder);
      await tester.pumpAndSettle();

      // 5. Active Examination Screen
      expect(find.byKey(const Key('exam_timer_display')), findsOneWidget);
      expect(find.byKey(const Key('exam_submit_button')), findsOneWidget);

      // Verify Question 1 is visible
      expect(find.textContaining('Question 1 of 10'), findsOneWidget);
      expect(
        find.textContaining('time complexity of searching for an element in a balanced Binary Search Tree'),
        findsOneWidget,
      );

      // Select Option B (index 1: 'O(log n)')
      final optionB = find.byKey(const Key('option_mcq_1_1'));
      expect(optionB, findsOneWidget);
      await tester.tap(optionB);
      await tester.pumpAndSettle();

      // Mark for Review
      final reviewToggle = find.byKey(const Key('review_toggle_mcq_1'));
      expect(reviewToggle, findsOneWidget);
      await tester.tap(reviewToggle);
      await tester.pumpAndSettle();

      // Navigate Next -> Question 2
      final nextButton = find.byKey(const Key('exam_next_button'));
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 2 of 10'), findsOneWidget);

      // Jump to Coding Challenge 1 via Question Palette (index 10)
      final codingPaletteItem = find.byKey(const Key('palette_item_10'));
      expect(codingPaletteItem, findsOneWidget);
      await tester.tap(codingPaletteItem);
      await tester.pumpAndSettle();

      // Verify Coding Challenge 1 view
      expect(find.textContaining('Coding Challenge 1 of 2'), findsOneWidget);
      expect(find.text('Valid Palindrome Checker'), findsOneWidget);
      expect(find.byKey(const Key('run_tests_button_code_1')), findsOneWidget);

      // 6. Submit Examination Flow
      final submitExamButton = find.byKey(const Key('exam_submit_button'));
      expect(submitExamButton, findsOneWidget);
      await tester.tap(submitExamButton);
      await tester.pumpAndSettle();

      // Verify Submission Confirmation Dialog
      expect(find.text('Submit Examination?'), findsOneWidget);
      final confirmSubmitButton = find.byKey(const Key('confirm_submit_button'));
      expect(confirmSubmitButton, findsOneWidget);

      await tester.tap(confirmSubmitButton);
      await tester.pumpAndSettle();

      // 7. Results Screen
      expect(find.text('Examination Completed'), findsOneWidget);
      expect(find.byKey(const Key('mcq_score_text')), findsOneWidget);
      expect(find.byKey(const Key('coding_status_text')), findsOneWidget);
      expect(find.textContaining('Manual submission by candidate'), findsOneWidget);
      expect(find.text('Prototype Assessment Notice'), findsOneWidget);

      // 8. Return to Home Screen
      final returnHomeButton = find.byKey(const Key('results_return_home_button'));
      expect(returnHomeButton, findsOneWidget);
      await tester.ensureVisible(returnHomeButton);
      await tester.tap(returnHomeButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsWidgets);
    },
  );
}
