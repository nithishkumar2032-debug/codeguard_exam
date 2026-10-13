import '../../../onboarding/models/candidate_details.dart';
import '../models/lifecycle_violation_result.dart';
import '../models/remote_exam_session.dart';
import '../models/save_response_result.dart';
import '../models/submit_session_result.dart';

export '../models/lifecycle_violation_result.dart';
export '../models/remote_exam_session.dart';
export '../models/save_response_result.dart';
export '../models/submit_session_result.dart';

/// Service contract defining communication with the server-authoritative exam backend.
abstract class RemoteExamService {
  /// Initiates or safely resumes an examination session on the server.
  ///
  /// - Associates the session with the authenticated candidate.
  /// - Enforces server-side 30-minute timing.
  /// - Returns existing terminal state if already submitted, expired, or terminated.
  /// - Returns null if running in unconfigured standalone/offline mode.
  Future<RemoteExamSession?> startOrResumeSession({
    required String examId,
    required CandidateDetails candidateDetails,
  });

  /// Persists a candidate's MCQ option selection and review flag.
  ///
  /// Validates session ownership, in-progress status, and expiry on the server.
  Future<SaveResponseResult> saveMcqResponse({
    required String sessionId,
    required String questionId,
    required int? selectedOption,
    bool isMarked = false,
    DateTime? clientSavedAt,
  });

  /// Persists a candidate's JavaScript coding solution draft.
  ///
  /// Validates session ownership, in-progress status, and expiry on the server.
  Future<SaveResponseResult> saveCodingDraft({
    required String sessionId,
    required String challengeId,
    required String codingDraft,
    bool isMarked = false,
    DateTime? clientSavedAt,
  });

  /// Records a lifecycle interruption signal (tab switch, window blur) on the server.
  ///
  /// Enforces server-side deduplication and the 2-strike termination policy.
  Future<LifecycleViolationResult> recordLifecycleViolation({
    required String sessionId,
    required String signalType,
    DateTime? clientTimestamp,
    Map<String, dynamic>? metadata,
    CandidateDetails? candidateDetails,
  });

  /// Submits the exam session and triggers server-authoritative scoring.
  ///
  /// Idempotent: repeated calls do not award duplicate scores or create duplicate results.
  Future<SubmitSessionResult> submitExamSession({
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  });
}
