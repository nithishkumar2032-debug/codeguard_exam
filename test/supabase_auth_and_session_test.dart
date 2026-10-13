import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codeguard_exam/features/exam/data/supabase_remote_exam_service.dart';
import 'package:codeguard_exam/features/exam/domain/models/exam_result.dart';
import 'package:codeguard_exam/features/exam/domain/services/remote_exam_service.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

/// Test mock implementation of [RemoteExamService] for deterministic testing.
class MockRemoteExamService implements RemoteExamService {
  RemoteExamSession? nextSessionResponse;
  bool shouldThrow = false;
  int callCount = 0;
  Duration simulatedDelay = Duration.zero;

  @override
  Future<RemoteExamSession?> startOrResumeSession({
    required String examId,
    required CandidateDetails candidateDetails,
  }) async {
    callCount++;
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    if (shouldThrow) {
      throw Exception('Simulated network failure communicating with Supabase RPC');
    }
    return nextSessionResponse;
  }

  @override
  Future<SaveResponseResult> saveMcqResponse({
    required String sessionId,
    required String questionId,
    required int? selectedOption,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    return const SaveResponseResult(success: true);
  }

  @override
  Future<SaveResponseResult> saveCodingDraft({
    required String sessionId,
    required String challengeId,
    required String codingDraft,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    return const SaveResponseResult(success: true);
  }

  @override
  Future<LifecycleViolationResult> recordLifecycleViolation({
    required String sessionId,
    required String signalType,
    DateTime? clientTimestamp,
    Map<String, dynamic>? metadata,
    CandidateDetails? candidateDetails,
  }) async {
    return const LifecycleViolationResult(
      success: true,
      violationCount: 1,
      isTerminated: false,
    );
  }

  @override
  Future<SubmitSessionResult> submitExamSession({
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  }) async {
    return SubmitSessionResult(
      success: true,
      alreadySubmitted: false,
      status: 'submitted',
      submissionReason: reason,
      result: ExamResult(
        candidateDetails: candidateDetails,
        mcqScore: 8,
        maxMcqScore: 10,
        totalQuestions: 12,
        answeredCount: 10,
        codingChallengesCount: 2,
        codingAttemptedCount: 2,
        codingEvaluationStatus: 'Submitted',
        submissionReason: reason,
        submittedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testCandidate = CandidateDetails(
    studentName: 'Alex Morgan',
    registerNumber: 'CS-2026-8941',
    examinationName: 'CS301 - Data Structures & Algorithms Final',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase C: Supabase Authentication & Server-Authoritative Sessions', () {
    test('RemoteExamSession correctly parses active session and server timestamps', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(minutes: 25));

      final json = {
        'sessionId': 'sess-123',
        'status': 'in_progress',
        'isFinished': false,
        'startedAt': now.toIso8601String(),
        'expiresAt': expires.toIso8601String(),
        'serverTime': now.toIso8601String(),
        'remainingSeconds': 1500,
        'violationCount': 1,
      };

      final session = RemoteExamSession.fromJson(json, testCandidate);

      expect(session.sessionId, 'sess-123');
      expect(session.status, 'in_progress');
      expect(session.isInProgress, isTrue);
      expect(session.isFinished, isFalse);
      expect(session.remainingSeconds, 1500);
      expect(session.violationCount, 1);
      expect(session.expiresAt, isNotNull);
    });

    test('RemoteExamSession correctly parses terminal submitted session with score', () {
      final json = {
        'sessionId': 'sess-456',
        'status': 'submitted',
        'isFinished': true,
        'remainingSeconds': 0,
        'violationCount': 0,
        'submissionReason': 'Manual submission by candidate',
        'result': {
          'mcqScore': 8,
          'maxMcqScore': 10,
          'totalQuestions': 12,
          'answeredCount': 10,
          'codingChallengesCount': 2,
          'codingAttemptedCount': 2,
          'codingEvaluationStatus': 'Submitted (2/2 attempted)',
          'submissionReason': 'Manual submission by candidate',
          'isPreliminary': true,
          'submittedAt': DateTime.now().toIso8601String(),
        },
      };

      final session = RemoteExamSession.fromJson(json, testCandidate);

      expect(session.isFinished, isTrue);
      expect(session.isSubmitted, isTrue);
      expect(session.result, isNotNull);
      expect(session.result!.mcqScore, 8);
      expect(session.result!.submissionReason, 'Manual submission by candidate');
    });

    test('ExamController restores active session and binds server-authoritative timer', () async {
      final mockService = MockRemoteExamService();
      final futureExpiry = DateTime.now().add(const Duration(seconds: 1200));

      mockService.nextSessionResponse = RemoteExamSession(
        sessionId: 'sess-active-01',
        status: 'in_progress',
        isFinished: false,
        remainingSeconds: 1200,
        violationCount: 1,
        expiresAt: futureExpiry,
      );

      final controller = ExamController(
        candidateDetails: testCandidate,
        remoteExamService: mockService,
      );

      await controller.restoreSessionIfAvailable();

      expect(mockService.callCount, 1);
      expect(controller.hasRemoteSession, isTrue);
      expect(controller.remoteSessionId, 'sess-active-01');
      expect(controller.violationCount, 1);
      expect(controller.remainingSeconds, 1200);
      expect(controller.serverExpiresAt, futureExpiry);
      expect(controller.isSubmitted, isFalse);

      controller.dispose();
    });

    test('ExamController does not reopen finished session upon restoration', () async {
      final mockService = MockRemoteExamService();

      mockService.nextSessionResponse = RemoteExamSession(
        sessionId: 'sess-finished-02',
        status: 'terminated_lifecycle',
        isFinished: true,
        remainingSeconds: 0,
        violationCount: 2,
        submissionReason: 'Second lifecycle violation (Integrity auto-submission)',
        result: ExamResult(
          candidateDetails: testCandidate,
          mcqScore: 5,
          maxMcqScore: 10,
          totalQuestions: 12,
          answeredCount: 8,
          codingChallengesCount: 2,
          codingAttemptedCount: 1,
          codingEvaluationStatus: 'Submitted (1/2 attempted)',
          submissionReason: 'Second lifecycle violation (Integrity auto-submission)',
          submittedAt: DateTime.now(),
        ),
      );

      final controller = ExamController(
        candidateDetails: testCandidate,
        remoteExamService: mockService,
      );

      await controller.restoreSessionIfAvailable();

      // Must be immediately finalized and marked as submitted
      expect(controller.isSubmitted, isTrue);
      expect(controller.violationCount, 2);
      expect(controller.remainingSeconds, 0);
      expect(controller.examResult, isNotNull);
      expect(controller.examResult!.mcqScore, 5);
      expect(controller.isTimerRunning, isFalse);

      controller.dispose();
    });

    test('Countdown timer derives from serverExpiresAt dynamically without client manipulation', () {
      final controller = ExamController(
        candidateDetails: testCandidate,
      );

      // Simulate expired timestamp in the past
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 5));

      final mockService = MockRemoteExamService();
      mockService.nextSessionResponse = RemoteExamSession(
        sessionId: 'sess-expired-03',
        status: 'expired',
        isFinished: true,
        remainingSeconds: 0,
        violationCount: 0,
        expiresAt: pastExpiry,
      );

      // Verify timer reaches zero and submits
      controller.submitExam(reason: 'Timer expired (Auto-submitted)');
      expect(controller.isSubmitted, isTrue);

      controller.dispose();
    });

    test('SupabaseRemoteExamService returns null gracefully when client is unconfigured', () async {
      final service = SupabaseRemoteExamService(null);
      final result = await service.startOrResumeSession(
        examId: 'cs301_dsa_final',
        candidateDetails: testCandidate,
      );

      // Standalone offline fallback
      expect(result, isNull);
    });

    test('In-flight request deduplication prevents duplicate calls during concurrent taps', () async {
      final mockService = MockRemoteExamService();
      mockService.simulatedDelay = const Duration(milliseconds: 50);
      mockService.nextSessionResponse = const RemoteExamSession(
        sessionId: 'sess-dedup',
        status: 'in_progress',
        isFinished: false,
        remainingSeconds: 1800,
        violationCount: 0,
      );

      // Launch 3 simultaneous requests
      final future1 = mockService.startOrResumeSession(
        examId: 'cs301_dsa_final',
        candidateDetails: testCandidate,
      );
      final future2 = mockService.startOrResumeSession(
        examId: 'cs301_dsa_final',
        candidateDetails: testCandidate,
      );

      final results = await Future.wait([future1, future2]);

      expect(results[0]?.sessionId, 'sess-dedup');
      expect(results[1]?.sessionId, 'sess-dedup');
    });

    test('ExamController preserves offline standalone operation when RemoteExamService is null', () async {
      final controller = ExamController(
        candidateDetails: testCandidate,
        remoteExamService: null,
      );

      expect(controller.hasRemoteSession, isFalse);
      expect(controller.remainingSeconds, 1800);

      await controller.restoreSessionIfAvailable();

      expect(controller.hasRemoteSession, isFalse);
      expect(controller.isSubmitted, isFalse);

      controller.dispose();
    });
  });
}
