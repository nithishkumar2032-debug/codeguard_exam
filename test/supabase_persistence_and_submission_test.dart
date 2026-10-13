import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codeguard_exam/features/exam/domain/models/exam_result.dart';
import 'package:codeguard_exam/features/exam/domain/services/remote_exam_service.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

/// Test mock implementation of [RemoteExamService] tracking Phase D RPC invocations.
class PhaseDMockRemoteExamService implements RemoteExamService {
  RemoteExamSession? initialSession;
  SaveResponseResult nextMcqResult = const SaveResponseResult(success: true);
  SaveResponseResult nextCodingResult = const SaveResponseResult(success: true);
  LifecycleViolationResult nextViolationResult = const LifecycleViolationResult(
    success: true,
    violationCount: 1,
    isTerminated: false,
  );
  SubmitSessionResult? nextSubmitResult;

  int startSessionCalls = 0;
  int saveMcqCalls = 0;
  int saveCodingCalls = 0;
  int recordViolationCalls = 0;
  int submitSessionCalls = 0;

  String? lastSavedQuestionId;
  int? lastSavedOptionIndex;
  bool? lastSavedMcqMarked;

  String? lastSavedChallengeId;
  String? lastSavedDraft;
  bool? lastSavedCodingMarked;

  String? lastViolationSignal;
  String? lastSubmitReason;

  bool shouldThrowOnSave = false;
  bool shouldThrowOnSubmit = false;

  @override
  Future<RemoteExamSession?> startOrResumeSession({
    required String examId,
    required CandidateDetails candidateDetails,
  }) async {
    startSessionCalls++;
    return initialSession ??
        RemoteExamSession(
          sessionId: 'test-session-uuid-101',
          status: 'in_progress',
          isFinished: false,
          remainingSeconds: 1800,
          violationCount: 0,
        );
  }

  @override
  Future<SaveResponseResult> saveMcqResponse({
    required String sessionId,
    required String questionId,
    required int? selectedOption,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    saveMcqCalls++;
    lastSavedQuestionId = questionId;
    lastSavedOptionIndex = selectedOption;
    lastSavedMcqMarked = isMarked;

    if (shouldThrowOnSave) {
      throw Exception('Simulated network failure on MCQ persistence');
    }
    return nextMcqResult;
  }

  @override
  Future<SaveResponseResult> saveCodingDraft({
    required String sessionId,
    required String challengeId,
    required String codingDraft,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    saveCodingCalls++;
    lastSavedChallengeId = challengeId;
    lastSavedDraft = codingDraft;
    lastSavedCodingMarked = isMarked;

    if (shouldThrowOnSave) {
      throw Exception('Simulated network failure on coding draft persistence');
    }
    return nextCodingResult;
  }

  @override
  Future<LifecycleViolationResult> recordLifecycleViolation({
    required String sessionId,
    required String signalType,
    DateTime? clientTimestamp,
    Map<String, dynamic>? metadata,
    CandidateDetails? candidateDetails,
  }) async {
    recordViolationCalls++;
    lastViolationSignal = signalType;
    return nextViolationResult;
  }

  @override
  Future<SubmitSessionResult> submitExamSession({
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  }) async {
    submitSessionCalls++;
    lastSubmitReason = reason;

    if (shouldThrowOnSubmit) {
      throw Exception('Simulated network failure on exam submission');
    }

    return nextSubmitResult ??
        SubmitSessionResult(
          success: true,
          alreadySubmitted: false,
          status: 'submitted',
          submissionReason: reason,
          result: ExamResult(
            candidateDetails: candidateDetails,
            mcqScore: 9,
            maxMcqScore: 10,
            totalQuestions: 12,
            answeredCount: 10,
            codingChallengesCount: 2,
            codingAttemptedCount: 2,
            codingEvaluationStatus: 'Evaluated by Server Suite',
            submissionReason: reason,
            submittedAt: DateTime.now(),
          ),
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const candidate = CandidateDetails(
    studentName: 'Morgan Vance',
    registerNumber: 'CS-2026-4421',
    examinationName: 'CS301 - Data Structures Final',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase D: Answer Persistence, Expiry, Submission & Integrity Grading', () {
    test('MCQ response persistence syncs selection and review flag with backend', () async {
      final mock = PhaseDMockRemoteExamService();
      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();
      expect(controller.hasRemoteSession, isTrue);

      controller.selectMcqOption('mcq_1', 2);
      await pumpEventQueue();

      expect(mock.saveMcqCalls, 1);
      expect(mock.lastSavedQuestionId, 'mcq_1');
      expect(mock.lastSavedOptionIndex, 2);
      expect(mock.lastSavedMcqMarked, false);

      // Toggle review flag and verify sync updates review state
      controller.toggleReviewFlag('mcq_1');
      await pumpEventQueue();

      expect(mock.saveMcqCalls, 2);
      expect(mock.lastSavedMcqMarked, true);
    });

    test('JavaScript coding draft persistence syncs code edits with backend', () async {
      final mock = PhaseDMockRemoteExamService();
      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();

      const candidateSolution = 'function reverseString(str) { return str.split("").reverse().join(""); }';
      controller.updateCodingDraft('code_1', candidateSolution);
      await pumpEventQueue();

      expect(mock.saveCodingCalls, 1);
      expect(mock.lastSavedChallengeId, 'code_1');
      expect(mock.lastSavedDraft, candidateSolution);
      expect(mock.lastSavedCodingMarked, false);
    });

    test('Server-side expiry auto-submits exam when response persistence returns expired', () async {
      final mock = PhaseDMockRemoteExamService();
      mock.nextMcqResult = const SaveResponseResult(
        success: false,
        status: 'expired',
        message: 'Exam duration expired',
      );

      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();
      controller.startTimer();
      expect(controller.isSubmitted, isFalse);

      controller.selectMcqOption('mcq_1', 1);
      await pumpEventQueue();

      // Controller must immediately finalize state due to server expiry
      expect(controller.isSubmitted, isTrue);
      expect(controller.examResult?.submissionReason, 'Timer expired (Auto-submitted)');
      expect(controller.isTimerRunning, isFalse);
    });

    test('Network failures during answer persistence do not crash app or corrupt local draft', () async {
      final mock = PhaseDMockRemoteExamService();
      mock.shouldThrowOnSave = true;

      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();

      // Selecting an option despite network exception
      expect(() => controller.selectMcqOption('mcq_2', 3), returnsNormally);
      await pumpEventQueue();

      expect(controller.mcqAnswers['mcq_2'], 3);
      expect(controller.isSubmitted, isFalse);
    });

    test('Server-authoritative scoring via submitExamAsync applies official server result', () async {
      final mock = PhaseDMockRemoteExamService();
      mock.nextSubmitResult = SubmitSessionResult(
        success: true,
        alreadySubmitted: false,
        status: 'submitted',
        submissionReason: 'Manual submission by candidate',
        result: ExamResult(
          candidateDetails: candidate,
          mcqScore: 10,
          maxMcqScore: 10,
          totalQuestions: 12,
          answeredCount: 10,
          codingChallengesCount: 2,
          codingAttemptedCount: 2,
          codingEvaluationStatus: 'Passed (100% hidden tests validated)',
          submissionReason: 'Manual submission by candidate',
          submittedAt: DateTime.now(),
          isPreliminary: false,
        ),
      );

      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();

      final result = await controller.submitExamAsync(reason: 'Manual submission by candidate');

      expect(mock.submitSessionCalls, 1);
      expect(result.mcqScore, 10);
      expect(result.codingEvaluationStatus, 'Passed (100% hidden tests validated)');
      expect(result.isPreliminary, false);
      expect(controller.isSubmitted, isTrue);
    });

    test('Repeated submissions are idempotent and prevent duplicate results', () async {
      final mock = PhaseDMockRemoteExamService();
      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();

      final firstResult = await controller.submitExamAsync(reason: 'First submit');
      final secondResult = await controller.submitExamAsync(reason: 'Duplicate submit');

      expect(firstResult.mcqScore, secondResult.mcqScore);
      expect(firstResult.submissionReason, secondResult.submissionReason);
      expect(controller.isSubmitted, isTrue);
    });

    test('Second lifecycle violation atomically terminates exam on server', () async {
      final mock = PhaseDMockRemoteExamService();
      mock.nextViolationResult = SubmitSessionResult(
        success: true,
        alreadySubmitted: false,
        status: 'terminated_lifecycle',
        submissionReason: 'Second lifecycle violation (Integrity auto-submission)',
        result: ExamResult(
          candidateDetails: candidate,
          mcqScore: 7,
          maxMcqScore: 10,
          totalQuestions: 12,
          answeredCount: 7,
          codingChallengesCount: 2,
          codingAttemptedCount: 0,
          codingEvaluationStatus: 'Terminated due to integrity breach',
          submissionReason: 'Second lifecycle violation (Integrity auto-submission)',
          submittedAt: DateTime.now(),
        ),
      ).let((s) => LifecycleViolationResult(
            success: true,
            violationCount: 2,
            isTerminated: true,
            reason: s.submissionReason,
            result: s.result,
          ));

      final controller = ExamController(
        candidateDetails: candidate,
        remoteExamService: mock,
      );

      await controller.restoreSessionIfAvailable();
      controller.recordViolation(2, signalType: 'documentHidden');
      await pumpEventQueue();

      expect(mock.recordViolationCalls, 1);
      expect(mock.lastViolationSignal, 'documentHidden');
      expect(controller.isSubmitted, isTrue);
      expect(controller.violationCount, 2);
      expect(controller.examResult?.codingEvaluationStatus, 'Terminated due to integrity breach');
    });

    test('Question models and starter templates strictly omit answer keys and hidden tests', () {
      final controller = ExamController(candidateDetails: candidate);

      // 1. Verify MCQs have options but no correct index field
      for (final mcq in controller.mcqs) {
        final json = mcq.toJson();
        expect(json.containsKey('correctOptionIndex'), isFalse);
        expect(json.containsKey('answerKey'), isFalse);
      }

      // 2. Verify Coding Challenges have public sample test cases without secret tests
      for (final challenge in controller.codingChallenges) {
        final json = challenge.toJson();
        final testCases = json['testCases'] as List;
        for (final tc in testCases) {
          expect(tc['isHidden'], isFalse);
        }
      }
    });
  });
}

extension _LetExt<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
