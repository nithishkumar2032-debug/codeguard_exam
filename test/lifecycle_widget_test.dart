import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codeguard_exam/features/exam/domain/services/lifecycle/browser_lifecycle_signal.dart';
import 'package:codeguard_exam/features/exam/domain/services/lifecycle/exam_lifecycle_adapter_stub.dart';
import 'package:codeguard_exam/features/exam/domain/services/lifecycle/exam_lifecycle_monitor.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/exam/presentation/screens/exam_screen.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Lifecycle Integration: First violation displays warning dialog, second violation auto-submits to results screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const candidate = CandidateDetails(
        studentName: 'Alex Morgan',
        registerNumber: 'CS-2026-8941',
        examinationName: 'Data Structures & Algorithms Final',
      );

      final controller = ExamController(candidateDetails: candidate);
      final adapter = BrowserLifecycleAdapter();
      final monitor = ExamLifecycleMonitor(
        controller: controller,
        adapter: adapter,
      );

      // Launch CodeGuardApp with pre-wired ExamScreen via routes
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => ExamScreen(
                  candidateDetails: candidate,
                  controller: controller,
                  lifecycleMonitor: monitor,
                ),
            '/results': (context) => Scaffold(
                  body: Center(
                    child: Text(
                      'Exam Auto-Submitted: ${controller.examResult?.submissionReason}',
                    ),
                  ),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exam_timer_display')), findsOneWidget);
      expect(monitor.isMonitoring, isTrue);

      // 1. First interruption: Candidate navigates to another browser tab
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await tester.pump();

      expect(controller.violationCount, 1);

      // Candidate returns to the exam window
      adapter.emitSignal(BrowserLifecycleSignal.documentVisible);
      await tester.pumpAndSettle();

      // Verify Integrity Warning Dialog appeared
      expect(find.text('Integrity Warning (1 of 2)'), findsOneWidget);
      final acknowledgeButton = find.byKey(const Key('acknowledge_warning_button'));
      expect(acknowledgeButton, findsOneWidget);

      // Candidate acknowledges warning
      await tester.tap(acknowledgeButton);
      await tester.pumpAndSettle();

      // Verify dialog dismissed and violation badge appears
      expect(find.text('Integrity Warning (1 of 2)'), findsNothing);
      expect(find.text('Violation 1/2'), findsOneWidget);

      // 2. Second interruption: Candidate navigates away again
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await tester.pumpAndSettle();

      // Verify second violation triggered auto-submission and navigated to results
      expect(controller.violationCount, 2);
      expect(controller.isSubmitted, isTrue);
      expect(find.textContaining('Second lifecycle violation (Integrity auto-submission)'), findsOneWidget);
      expect(monitor.isMonitoring, isFalse);

      monitor.dispose();
      controller.dispose();
    },
  );
}
