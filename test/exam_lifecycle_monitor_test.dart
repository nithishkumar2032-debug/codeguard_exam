import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codeguard_exam/features/exam/domain/services/lifecycle/browser_lifecycle_signal.dart';
import 'package:codeguard_exam/features/exam/domain/services/lifecycle/exam_lifecycle_adapter_stub.dart';
import 'package:codeguard_exam/features/exam/domain/services/lifecycle/exam_lifecycle_monitor.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testCandidate = CandidateDetails(
    studentName: 'Lifecycle Test Student',
    registerNumber: 'REG-LIFE-01',
    examinationName: 'Integrity Monitoring Final',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExamLifecycleMonitor Unit Tests', () {
    test('Lifecycle events outside an active exam are strictly ignored', () {
      final controller = ExamController(candidateDetails: testCandidate);
      final adapter = BrowserLifecycleAdapter();
      final monitor = ExamLifecycleMonitor(
        controller: controller,
        adapter: adapter,
      );

      expect(monitor.isMonitoring, isFalse);

      // Emit signals before startMonitoring()
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      adapter.emitSignal(BrowserLifecycleSignal.windowBlur);

      expect(controller.violationCount, 0);
      expect(controller.isSubmitted, isFalse);
      expect(monitor.isInBackground, isFalse);

      monitor.dispose();
      controller.dispose();
    });

    test('First interruption records violation #1 and triggers warning callback on return', () async {
      final controller = ExamController(candidateDetails: testCandidate);
      final adapter = BrowserLifecycleAdapter();
      bool warningTriggered = false;

      final monitor = ExamLifecycleMonitor(
        controller: controller,
        adapter: adapter,
        onFirstViolationWarning: () {
          warningTriggered = true;
        },
      );

      monitor.startMonitoring();
      expect(monitor.isMonitoring, isTrue);

      // 1. Candidate navigates away (primary signal: documentHidden)
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);

      expect(controller.violationCount, 1);
      expect(monitor.isInBackground, isTrue);
      expect(monitor.hasPendingWarning, isTrue);
      expect(controller.isSubmitted, isFalse);
      expect(warningTriggered, isFalse); // Warning is displayed when candidate returns

      // 2. Candidate returns to the exam window (documentVisible)
      adapter.emitSignal(BrowserLifecycleSignal.documentVisible);
      await Future.delayed(Duration.zero);

      expect(monitor.isInBackground, isFalse);
      expect(monitor.hasPendingWarning, isFalse);
      expect(warningTriggered, isTrue); // Warning successfully fired upon return

      monitor.dispose();
      controller.dispose();
    });

    test('Deduplicates overlapping browser events during a single transition', () async {
      final controller = ExamController(candidateDetails: testCandidate);
      final adapter = BrowserLifecycleAdapter();

      final monitor = ExamLifecycleMonitor(
        controller: controller,
        adapter: adapter,
      );

      monitor.startMonitoring();

      // Browser emits both documentHidden AND windowBlur in rapid succession
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      adapter.emitSignal(BrowserLifecycleSignal.windowBlur);
      adapter.emitSignal(BrowserLifecycleSignal.windowBlur);
      await Future.delayed(Duration.zero);

      // Must be deduplicated to count as exactly 1 interruption
      expect(controller.violationCount, 1);
      expect(monitor.isInBackground, isTrue);

      monitor.dispose();
      controller.dispose();
    });

    test('Second interruption triggers automatic submission through idempotent pathway', () async {
      final controller = ExamController(candidateDetails: testCandidate);
      final adapter = BrowserLifecycleAdapter();

      final monitor = ExamLifecycleMonitor(
        controller: controller,
        adapter: adapter,
      );

      monitor.startMonitoring();

      // First interruption
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);
      adapter.emitSignal(BrowserLifecycleSignal.documentVisible);
      await Future.delayed(const Duration(milliseconds: 600)); // allow cooldown

      expect(controller.violationCount, 1);
      expect(controller.isSubmitted, isFalse);

      // Second interruption
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);

      expect(controller.violationCount, 2);
      expect(controller.isSubmitted, isTrue);
      expect(
        controller.examResult?.submissionReason,
        'Second lifecycle violation (Integrity auto-submission)',
      );
      expect(monitor.isMonitoring, isFalse); // Monitoring ceased

      // Events after exam is submitted are ignored
      adapter.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);
      expect(controller.violationCount, 2); // Does not increment further

      monitor.dispose();
      controller.dispose();
    });

    test('Submission idempotency: manual submission and lifecycle submission do not conflict', () {
      final controller = ExamController(candidateDetails: testCandidate);

      // Manual submission
      final result1 = controller.submitExam(reason: 'Manual candidate submission');
      expect(controller.isSubmitted, isTrue);

      // Attempt lifecycle auto-submission
      final result2 = controller.submitExam(
        reason: 'Second lifecycle violation (Integrity auto-submission)',
      );

      expect(identical(result1, result2), isTrue);
      expect(result2.submissionReason, 'Manual candidate submission');

      controller.dispose();
    });

    test('Persistence maintains violation count across session restoration', () async {
      final controller1 = ExamController(candidateDetails: testCandidate);
      final adapter1 = BrowserLifecycleAdapter();

      final monitor1 = ExamLifecycleMonitor(
        controller: controller1,
        adapter: adapter1,
      );

      monitor1.startMonitoring();

      // Trigger violation 1 and persist
      adapter1.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);
      expect(controller1.violationCount, 1);
      await controller1.persistSession();

      // Simulate page refresh recovery
      final controller2 = ExamController(candidateDetails: testCandidate);
      await controller2.restoreSessionIfAvailable();

      expect(controller2.violationCount, 1);

      // Second interruption on restored session
      final adapter2 = BrowserLifecycleAdapter();
      final monitor2 = ExamLifecycleMonitor(
        controller: controller2,
        adapter: adapter2,
      );
      monitor2.startMonitoring();

      adapter2.emitSignal(BrowserLifecycleSignal.documentHidden);
      await Future.delayed(Duration.zero);

      expect(controller2.violationCount, 2);
      expect(controller2.isSubmitted, isTrue);
      expect(
        controller2.examResult?.submissionReason,
        'Second lifecycle violation (Integrity auto-submission)',
      );

      monitor1.dispose();
      controller1.dispose();
      monitor2.dispose();
      controller2.dispose();
    });
  });
}
