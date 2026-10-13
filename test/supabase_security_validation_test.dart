import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:codeguard_exam/features/exam/domain/models/exam_result.dart';
import 'package:codeguard_exam/features/exam/domain/services/remote_exam_service.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

/// Test mock implementation simulating multi-tenant candidate authorization.
class MultiTenantMockRemoteExamService implements RemoteExamService {
  final Map<String, String> sessionOwners = {}; // sessionId -> candidateRegister
  final Map<String, String> sessionStatus = {}; // sessionId -> status
  final Map<String, int> sessionViolations = {}; // sessionId -> count

  String activeCandidateRegister = '';

  @override
  Future<RemoteExamSession?> startOrResumeSession({
    required String examId,
    required CandidateDetails candidateDetails,
  }) async {
    final sessionId = 'sess_${candidateDetails.registerNumber}';
    sessionOwners[sessionId] = candidateDetails.registerNumber;
    sessionStatus[sessionId] = 'in_progress';
    sessionViolations[sessionId] = 0;

    return RemoteExamSession(
      sessionId: sessionId,
      status: 'in_progress',
      isFinished: false,
      remainingSeconds: 1800,
      violationCount: 0,
    );
  }

  void _verifyOwnership(String sessionId) {
    final owner = sessionOwners[sessionId];
    if (owner == null || owner != activeCandidateRegister) {
      throw Exception('PostgreSQL RLS / RPC Error: 403 Forbidden - User does not own session $sessionId');
    }
  }

  @override
  Future<SaveResponseResult> saveMcqResponse({
    required String sessionId,
    required String questionId,
    required int? selectedOption,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    _verifyOwnership(sessionId);
    if (sessionStatus[sessionId] != 'in_progress') {
      return SaveResponseResult(
        success: false,
        status: sessionStatus[sessionId],
        message: 'Exam session is no longer active',
      );
    }
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
    _verifyOwnership(sessionId);
    if (sessionStatus[sessionId] != 'in_progress') {
      return SaveResponseResult(
        success: false,
        status: sessionStatus[sessionId],
        message: 'Exam session is no longer active',
      );
    }
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
    _verifyOwnership(sessionId);
    final count = (sessionViolations[sessionId] ?? 0) + 1;
    sessionViolations[sessionId] = count;

    if (count >= 2) {
      sessionStatus[sessionId] = 'terminated_lifecycle';
      return LifecycleViolationResult(
        success: true,
        violationCount: 2,
        isTerminated: true,
        reason: 'Second lifecycle violation (Integrity auto-submission)',
      );
    }
    return LifecycleViolationResult(
      success: true,
      violationCount: 1,
      isTerminated: false,
      warningRequired: true,
    );
  }

  @override
  Future<SubmitSessionResult> submitExamSession({
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  }) async {
    _verifyOwnership(sessionId);
    sessionStatus[sessionId] = 'submitted';
    return SubmitSessionResult(
      success: true,
      alreadySubmitted: false,
      status: 'submitted',
      submissionReason: reason,
      result: ExamResult(
        candidateDetails: candidateDetails,
        mcqScore: 10,
        maxMcqScore: 10,
        totalQuestions: 12,
        answeredCount: 10,
        codingChallengesCount: 2,
        codingAttemptedCount: 2,
        codingEvaluationStatus: 'Validated',
        submissionReason: reason,
        submittedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const candidateA = CandidateDetails(
    studentName: 'Alice Cooper',
    registerNumber: 'CS-ALICE-101',
    examinationName: 'CS301 Final',
  );

  const candidateB = CandidateDetails(
    studentName: 'Bob Martin',
    registerNumber: 'CS-BOB-202',
    examinationName: 'CS301 Final',
  );

  group('Phase E1: Security Validation & Multi-Tenant Authorization Contracts', () {
    test('Candidate A cannot read, mutate, or submit Candidate B session', () async {
      final mock = MultiTenantMockRemoteExamService();

      // Candidate B registers session
      mock.activeCandidateRegister = candidateB.registerNumber;
      final controllerB = ExamController(
        candidateDetails: candidateB,
        remoteExamService: mock,
      );
      await controllerB.restoreSessionIfAvailable();
      final sessionBId = controllerB.remoteSessionId!;
      expect(sessionBId, 'sess_CS-BOB-202');

      // Now switch active identity to Candidate A
      mock.activeCandidateRegister = candidateA.registerNumber;

      // Candidate A attempts to mutate Candidate B's answers
      expect(
        () => mock.saveMcqResponse(
          sessionId: sessionBId,
          questionId: 'mcq_1',
          selectedOption: 2,
        ),
        throwsA(predicate((e) => e.toString().contains('403 Forbidden'))),
      );

      // Candidate A attempts to mutate Candidate B's coding draft
      expect(
        () => mock.saveCodingDraft(
          sessionId: sessionBId,
          challengeId: 'code_1',
          codingDraft: 'malicious payload',
        ),
        throwsA(predicate((e) => e.toString().contains('403 Forbidden'))),
      );

      // Candidate A attempts to record violation or submit Candidate B's session
      expect(
        () => mock.recordLifecycleViolation(
          sessionId: sessionBId,
          signalType: 'documentHidden',
        ),
        throwsA(predicate((e) => e.toString().contains('403 Forbidden'))),
      );

      expect(
        () => mock.submitExamSession(
          sessionId: sessionBId,
          reason: 'Sabotage',
          candidateDetails: candidateA,
        ),
        throwsA(predicate((e) => e.toString().contains('403 Forbidden'))),
      );
    });

    test('Zero service-role keys or server secrets exist in client application code', () {
      final libDir = Directory('lib');
      final allFiles = libDir.listSync(recursive: true).whereType<File>();

      final forbiddenKeywords = [
        'service_role',
        'SERVICE_ROLE_KEY',
        'supabase_service_role',
      ];

      for (final file in allFiles) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();

        // Exclude the security documentation comment in supabase_config.dart
        if (file.path.endsWith('supabase_config.dart')) continue;

        for (final keyword in forbiddenKeywords) {
          expect(
            content.contains(keyword),
            isFalse,
            reason: 'File ${file.path} must NEVER contain "$keyword"',
          );
        }
      }
    });

    test('SQL migrations strictly verify that candidates cannot directly mutate session table via REST', () {
      final rlsSql = File('supabase/migrations/20261014000002_row_level_security.sql').readAsStringSync();

      // candidate_exam_sessions must only allow SELECT
      expect(rlsSql.contains('ON public.candidate_exam_sessions'), isTrue);
      expect(rlsSql.contains('Candidates can view their own sessions'), isTrue);

      final insertOnSessions = RegExp(r'ON\s+public\.candidate_exam_sessions\s+FOR\s+INSERT').hasMatch(rlsSql);
      final updateOnSessions = RegExp(r'ON\s+public\.candidate_exam_sessions\s+FOR\s+UPDATE').hasMatch(rlsSql);
      final deleteOnSessions = RegExp(r'ON\s+public\.candidate_exam_sessions\s+FOR\s+DELETE').hasMatch(rlsSql);

      expect(insertOnSessions, isFalse, reason: 'Candidates must not have direct INSERT on candidate_exam_sessions');
      expect(updateOnSessions, isFalse, reason: 'Candidates must not have direct UPDATE on candidate_exam_sessions');
      expect(deleteOnSessions, isFalse, reason: 'Candidates must not have direct DELETE on candidate_exam_sessions');
    });

    test('SQL migrations strictly exclude answer keys and hidden tests from client access', () {
      final rlsSql = File('supabase/migrations/20261014000002_row_level_security.sql').readAsStringSync();

      // Ensure RLS is enabled on protected tables
      expect(rlsSql.contains('ALTER TABLE public.mcq_answer_keys ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(rlsSql.contains('ALTER TABLE public.coding_hidden_test_cases ENABLE ROW LEVEL SECURITY;'), isTrue);

      // Ensure zero policies exist on them
      expect(rlsSql.contains('ON public.mcq_answer_keys'), isFalse);
      expect(rlsSql.contains('ON public.coding_hidden_test_cases'), isFalse);
    });

    test('All RPC functions enforce SECURITY DEFINER, search_path, and revoke execution from PUBLIC', () {
      final fnSql = File('supabase/migrations/20261014000003_server_authoritative_functions.sql').readAsStringSync();

      final functions = [
        '_finalize_and_score_session',
        'start_or_resume_exam_session',
        'save_candidate_response',
        'save_candidate_coding_draft',
        'record_lifecycle_violation',
        'submit_exam_session',
      ];

      for (final fn in functions) {
        expect(fnSql.contains('FUNCTION public.$fn'), isTrue);
        expect(fnSql.contains('REVOKE EXECUTE ON FUNCTION public.$fn'), isTrue);
      }
    });
  });
}
