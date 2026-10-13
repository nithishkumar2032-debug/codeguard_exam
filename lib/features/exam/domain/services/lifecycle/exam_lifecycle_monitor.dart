import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../presentation/controllers/exam_controller.dart';
import 'browser_lifecycle_signal.dart';
import 'exam_lifecycle_adapter.dart';

/// Dedicated lifecycle-based integrity monitor for CodeGuard Exam.
///
/// Responsibilities:
/// - Listens to browser document visibility as primary signal, and window blur/focus as supporting signals.
/// - Deduplicates overlapping browser events so one transition into the background counts at most once.
/// - Disregards all events before the exam starts and after it ends.
/// - Manages the 2-strike interruption policy (warning on strike 1, automatic submission on strike 2).
///
/// Security & Tamper Disclaimer:
/// Client-side browser lifecycle monitoring provides deterrence and detection of tab switching
/// or unfocus events. Browser events alone do NOT constitute tamper-proof proctoring;
/// authoritative integrity requires invigilated, server-side evaluation.
class ExamLifecycleMonitor {
  final ExamController controller;
  final BrowserLifecycleAdapter adapter;

  /// Callback triggered when the candidate returns after their first recorded violation.
  VoidCallback? onFirstViolationWarning;

  bool _isMonitoring = false;
  bool _isInBackground = false;
  bool _hasPendingWarning = false;
  DateTime? _lastInterruptionTime;
  StreamSubscription<BrowserLifecycleSignal>? _subscription;

  final Duration debounceCooldown;

  ExamLifecycleMonitor({
    required this.controller,
    BrowserLifecycleAdapter? adapter,
    this.onFirstViolationWarning,
    this.debounceCooldown = Duration.zero,
  }) : adapter = adapter ?? BrowserLifecycleAdapter();

  bool get isMonitoring => _isMonitoring;
  bool get isInBackground => _isInBackground;
  bool get hasPendingWarning => _hasPendingWarning;

  /// Starts monitoring when the active examination session begins.
  void startMonitoring() {
    if (_isMonitoring || controller.isSubmitted) return;
    _isMonitoring = true;

    adapter.start();
    _subscription = adapter.signalStream.listen(_handleBrowserSignal);
  }

  /// Stops monitoring permanently (e.g. upon exam submission).
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    _subscription?.cancel();
    _subscription = null;
    adapter.stop();
  }

  /// Central event router handling visibility and focus transitions.
  void _handleBrowserSignal(BrowserLifecycleSignal signal) {
    // Rule 5: Ignore lifecycle events before the exam begins and after it ends
    if (!_isMonitoring || controller.isSubmitted) return;

    switch (signal) {
      case BrowserLifecycleSignal.documentHidden:
      case BrowserLifecycleSignal.windowBlur:
        _handleInterruptionTransition(signal);
        break;

      case BrowserLifecycleSignal.documentVisible:
      case BrowserLifecycleSignal.windowFocus:
        _handleResumptionTransition(signal);
        break;
    }
  }

  /// Handles candidate leaving the active test environment (tab switch / window unfocus).
  void _handleInterruptionTransition(BrowserLifecycleSignal signal) {
    final now = DateTime.now();

    // Deduplicate overlapping browser events so one transition counts at most once
    if (_isInBackground) {
      return; // Already in background state; ignore secondary signals
    }

    if (debounceCooldown > Duration.zero &&
        _lastInterruptionTime != null &&
        now.difference(_lastInterruptionTime!) < debounceCooldown) {
      return; // Within debounce cooldown of the same transition
    }

    _isInBackground = true;
    _lastInterruptionTime = now;

    final currentViolations = controller.violationCount + 1;
    controller.recordViolation(currentViolations);

    if (currentViolations == 1) {
      // First violation: Stage a warning for display when candidate returns
      _hasPendingWarning = true;
    } else if (currentViolations >= 2) {
      // Second violation: Terminate and submit exam via idempotent pathway
      stopMonitoring();
      controller.submitExam(
        reason: 'Second lifecycle violation (Integrity auto-submission)',
      );
    }
  }

  /// Handles candidate returning to the active test window.
  void _handleResumptionTransition(BrowserLifecycleSignal signal) {
    if (!_isInBackground) return;
    _isInBackground = false;

    // Trigger warning on returning from the first violation
    if (_hasPendingWarning && !controller.isSubmitted) {
      _hasPendingWarning = false;
      onFirstViolationWarning?.call();
    }
  }

  void dispose() {
    stopMonitoring();
    adapter.dispose();
  }
}
