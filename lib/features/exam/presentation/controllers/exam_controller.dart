import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/sample_coding_challenges.dart';
import '../../data/sample_mcqs.dart';
import '../../domain/models/coding_challenge.dart';
import '../../domain/models/exam_result.dart';
import '../../domain/models/mcq_question.dart';
import '../../domain/models/question_status.dart';
import '../../domain/services/code_execution_service.dart';
import '../../domain/services/exam_scoring_service.dart';
import '../../domain/services/exam_storage_service.dart';
import '../../domain/services/remote_exam_service.dart';
import '../../../onboarding/models/candidate_details.dart';

/// Central controller managing the entire examination lifecycle.
///
/// Responsibilities:
/// - Precise countdown timer execution without multiple overlapping timers.
/// - Question indexing, selection, navigation, and review flagging.
/// - Idempotent, duplicate-guarded submission (auto on timeout or candidate manual).
/// - Draft persistence for refresh recovery.
/// - Server-authoritative timing and session resumption.
class ExamController extends ChangeNotifier {
  final CandidateDetails candidateDetails;
  final ExamScoringService _scoringService;
  final ExamStorageService _storageService;
  final CodeExecutionService codeExecutionService;
  final RemoteExamService? remoteExamService;

  final List<McqQuestion> mcqs;
  final List<CodingChallenge> codingChallenges;

  int _currentIndex = 0;
  int _remainingSeconds = 30 * 60; // 30 minutes countdown = 1800 seconds
  int _violationCount = 0;
  Timer? _timer;
  bool _isSubmitted = false;
  ExamResult? _examResult;
  String? _remoteSessionId;
  DateTime? _serverExpiresAt;
  bool _hasRemoteSession = false;
  Future<ExamResult?>? _remoteSubmissionFuture;

  final Map<String, int> _mcqAnswers = {};
  final Map<String, String> _codingDrafts = {};
  final Set<String> _reviewFlags = {};

  ExamController({
    required this.candidateDetails,
    ExamScoringService? scoringService,
    ExamStorageService? storageService,
    CodeExecutionService? codeExecutionService,
    this.remoteExamService,
    List<McqQuestion>? mcqs,
    List<CodingChallenge>? codingChallenges,
  })  : _scoringService = scoringService ?? ExamScoringService(),
        _storageService = storageService ?? SharedPrefsExamStorageService(),
        codeExecutionService =
            codeExecutionService ?? SafePlaceholderCodeExecutionService(),
        mcqs = mcqs ?? SampleMcqs.questions,
        codingChallenges = codingChallenges ?? SampleCodingChallenges.challenges {
    // Initialize coding drafts with starter code
    for (final challenge in this.codingChallenges) {
      _codingDrafts[challenge.id] = challenge.starterCode;
    }
  }

  // --- Getters ---
  int get currentIndex => _currentIndex;
  int get remainingSeconds => _remainingSeconds;
  int get violationCount => _violationCount;
  bool get isSubmitted => _isSubmitted;
  ExamResult? get examResult => _examResult;
  bool get isTimerRunning => _timer != null && _timer!.isActive;
  String? get remoteSessionId => _remoteSessionId;
  DateTime? get serverExpiresAt => _serverExpiresAt;
  bool get hasRemoteSession => _hasRemoteSession;

  int get totalQuestionsCount => mcqs.length + codingChallenges.length;
  bool get isCurrentMcq => _currentIndex < mcqs.length;
  bool get isCurrentCoding => _currentIndex >= mcqs.length;

  McqQuestion? get currentMcq =>
      isCurrentMcq ? mcqs[_currentIndex] : null;

  CodingChallenge? get currentCodingChallenge => isCurrentCoding
      ? codingChallenges[_currentIndex - mcqs.length]
      : null;

  Map<String, int> get mcqAnswers => Map.unmodifiable(_mcqAnswers);
  Map<String, String> get codingDrafts => Map.unmodifiable(_codingDrafts);
  Set<String> get reviewFlags => Set.unmodifiable(_reviewFlags);

  int get answeredCount {
    int count = _mcqAnswers.length;
    for (final challenge in codingChallenges) {
      final draft = _codingDrafts[challenge.id];
      if (draft != null && draft.trim() != challenge.starterCode.trim()) {
        count++;
      }
    }
    return count;
  }

  int get markedForReviewCount => _reviewFlags.length;

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Timer Management ---

  /// Starts the countdown timer. Ensures no multiple timers run concurrently.
  void startTimer() {
    if (_isSubmitted) return;

    // Prevent multiple timers running simultaneously
    _timer?.cancel();
    _timer = null;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_serverExpiresAt != null) {
        // Server-authoritative countdown based on server expiry timestamp
        final now = DateTime.now();
        final diff = _serverExpiresAt!.difference(now).inSeconds;
        _remainingSeconds = diff > 0 ? diff : 0;
      } else if (_remainingSeconds > 0) {
        // Standalone offline decrement fallback
        _remainingSeconds--;
      }

      if (_remainingSeconds <= 0) {
        // Automatically submit when the timer reaches zero
        timer.cancel();
        _timer = null;
        submitExam(reason: 'Timer expired (Auto-submitted)');
      } else {
        notifyListeners();

        // Periodically save state to local storage every 15 seconds
        if (_remainingSeconds % 15 == 0) {
          _persistSession();
        }
      }
    });
  }

  /// Cancels the running timer resources.
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // --- Question Navigation & Actions ---

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestionsCount) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < totalQuestionsCount - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void selectMcqOption(String questionId, int optionIndex) {
    if (_isSubmitted) return;
    _mcqAnswers[questionId] = optionIndex;
    notifyListeners();
    _persistSession();

    if (_hasRemoteSession &&
        remoteExamService != null &&
        _remoteSessionId != null) {
      unawaited(_syncMcqResponse(questionId, optionIndex));
    }
  }

  void updateCodingDraft(String challengeId, String code) {
    if (_isSubmitted) return;
    _codingDrafts[challengeId] = code;
    notifyListeners();
    _persistSession();

    if (_hasRemoteSession &&
        remoteExamService != null &&
        _remoteSessionId != null) {
      unawaited(_syncCodingDraft(challengeId, code));
    }
  }

  void toggleReviewFlag(String questionOrChallengeId) {
    if (_isSubmitted) return;
    if (_reviewFlags.contains(questionOrChallengeId)) {
      _reviewFlags.remove(questionOrChallengeId);
    } else {
      _reviewFlags.add(questionOrChallengeId);
    }
    notifyListeners();
    _persistSession();

    if (_hasRemoteSession &&
        remoteExamService != null &&
        _remoteSessionId != null) {
      if (_mcqAnswers.containsKey(questionOrChallengeId)) {
        unawaited(_syncMcqResponse(
            questionOrChallengeId, _mcqAnswers[questionOrChallengeId]!));
      } else if (_codingDrafts.containsKey(questionOrChallengeId)) {
        unawaited(_syncCodingDraft(
            questionOrChallengeId, _codingDrafts[questionOrChallengeId]!));
      }
    }
  }

  QuestionStatus getQuestionStatus(int index) {
    if (index < mcqs.length) {
      final question = mcqs[index];
      final isAnswered = _mcqAnswers.containsKey(question.id);
      final isMarked = _reviewFlags.contains(question.id);

      if (isAnswered && isMarked) return QuestionStatus.answeredAndMarkedForReview;
      if (isAnswered) return QuestionStatus.answered;
      if (isMarked) return QuestionStatus.markedForReview;
      return QuestionStatus.unanswered;
    } else {
      final challenge = codingChallenges[index - mcqs.length];
      final draft = _codingDrafts[challenge.id];
      final isAnswered =
          draft != null && draft.trim() != challenge.starterCode.trim();
      final isMarked = _reviewFlags.contains(challenge.id);

      if (isAnswered && isMarked) return QuestionStatus.answeredAndMarkedForReview;
      if (isAnswered) return QuestionStatus.answered;
      if (isMarked) return QuestionStatus.markedForReview;
      return QuestionStatus.unanswered;
    }
  }

  // --- Submission ---

  /// Submits the exam. Protected against duplicate execution.
  ExamResult submitExam({required String reason}) {
    if (_isSubmitted && _examResult != null) {
      return _examResult!;
    }

    _isSubmitted = true;
    stopTimer();

    // Clear local draft state after final submission
    _storageService.clearSession();

    // Score MCQs using separate scoring service as preliminary/offline outcome
    _examResult = _scoringService.scoreSubmission(
      candidateDetails: candidateDetails,
      mcqAnswers: _mcqAnswers,
      codingDrafts: _codingDrafts,
      submissionReason: reason,
    );

    // If connected to remote Supabase session, trigger authoritative server submission
    if (_hasRemoteSession &&
        remoteExamService != null &&
        _remoteSessionId != null) {
      _remoteSubmissionFuture = _performRemoteSubmission(reason);
      unawaited(_remoteSubmissionFuture);
    }

    notifyListeners();
    return _examResult!;
  }

  /// Asynchronous variant of [submitExam] that awaits the server-authoritative submission RPC.
  Future<ExamResult> submitExamAsync({required String reason}) async {
    if (_isSubmitted && _examResult != null) {
      if (_remoteSubmissionFuture != null) {
        await _remoteSubmissionFuture;
      }
      return _examResult!;
    }

    submitExam(reason: reason);
    if (_remoteSubmissionFuture != null) {
      await _remoteSubmissionFuture;
    }
    return _examResult!;
  }

  void recordViolation(int count, {String? signalType}) {
    if (_isSubmitted) return;
    _violationCount = count;
    notifyListeners();
    _persistSession();

    if (_hasRemoteSession &&
        remoteExamService != null &&
        _remoteSessionId != null) {
      unawaited(_syncViolation(count, signalType: signalType));
    }
  }

  Future<void> _syncMcqResponse(String questionId, int optionIndex) async {
    try {
      final outcome = await remoteExamService!.saveMcqResponse(
        sessionId: _remoteSessionId!,
        questionId: questionId,
        selectedOption: optionIndex,
        isMarked: _reviewFlags.contains(questionId),
        clientSavedAt: DateTime.now(),
      );

      if (!outcome.success) {
        if (outcome.status == 'expired') {
          _handleServerExpiry();
        } else if (outcome.status == 'submitted' ||
            outcome.status == 'terminated_lifecycle') {
          _handleServerTermination(outcome.status!);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Remote MCQ answer sync failed: $e');
    }
  }

  Future<void> _syncCodingDraft(String challengeId, String code) async {
    try {
      final outcome = await remoteExamService!.saveCodingDraft(
        sessionId: _remoteSessionId!,
        challengeId: challengeId,
        codingDraft: code,
        isMarked: _reviewFlags.contains(challengeId),
        clientSavedAt: DateTime.now(),
      );

      if (!outcome.success) {
        if (outcome.status == 'expired') {
          _handleServerExpiry();
        } else if (outcome.status == 'submitted' ||
            outcome.status == 'terminated_lifecycle') {
          _handleServerTermination(outcome.status!);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Remote coding draft sync failed: $e');
    }
  }

  Future<void> _syncViolation(int count, {String? signalType}) async {
    try {
      final outcome = await remoteExamService!.recordLifecycleViolation(
        sessionId: _remoteSessionId!,
        signalType: signalType ?? 'documentHidden',
        clientTimestamp: DateTime.now(),
        candidateDetails: candidateDetails,
      );

      if (outcome.isTerminated) {
        _violationCount = outcome.violationCount;
        _isSubmitted = true;
        stopTimer();
        _storageService.clearSession();
        if (outcome.result != null) {
          _examResult = outcome.result;
        }
        notifyListeners();
      } else if (outcome.violationCount != _violationCount) {
        _violationCount = outcome.violationCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Remote lifecycle violation sync failed: $e');
    }
  }

  Future<ExamResult?> _performRemoteSubmission(String reason) async {
    try {
      final outcome = await remoteExamService!.submitExamSession(
        sessionId: _remoteSessionId!,
        reason: reason,
        candidateDetails: candidateDetails,
      );
      if (outcome.result != null) {
        _examResult = outcome.result;
        notifyListeners();
        return _examResult;
      }
    } catch (e) {
      debugPrint('⚠️ Remote exam submission failed: $e');
    }
    return _examResult;
  }

  void _handleServerExpiry() {
    if (_isSubmitted) return;
    submitExam(reason: 'Timer expired (Auto-submitted)');
  }

  void _handleServerTermination(String status) {
    if (_isSubmitted) return;
    _isSubmitted = true;
    stopTimer();
    _storageService.clearSession();
    notifyListeners();
  }

  // --- Persistence Recovery ---

  Future<void> restoreSessionIfAvailable() async {
    // 1. If remote exam service is provided, consult server for authoritative session state
    if (remoteExamService != null) {
      try {
        final remoteSession = await remoteExamService!.startOrResumeSession(
          examId: 'cs301_dsa_final',
          candidateDetails: candidateDetails,
        );

        if (remoteSession != null) {
          _hasRemoteSession = true;
          _remoteSessionId = remoteSession.sessionId;

          // Case A: Finished session (submitted, expired, or terminated).
          // Do not reopen finished sessions. Transition to terminal results state.
          if (remoteSession.isFinished) {
            _isSubmitted = true;
            _violationCount = remoteSession.violationCount;
            _remainingSeconds = 0;
            _examResult = remoteSession.result ??
                ExamResult(
                  candidateDetails: candidateDetails,
                  mcqScore: 0,
                  maxMcqScore: mcqs.length,
                  totalQuestions: totalQuestionsCount,
                  answeredCount: 0,
                  codingChallengesCount: codingChallenges.length,
                  codingAttemptedCount: 0,
                  codingEvaluationStatus: 'Finalized on server',
                  submissionReason:
                      remoteSession.submissionReason ?? 'Session concluded',
                  submittedAt: DateTime.now(),
                );
            stopTimer();
            notifyListeners();
            return;
          }

          // Case B: Active session resumed. Bind authoritative server timing and violation count.
          _serverExpiresAt = remoteSession.expiresAt;
          _remainingSeconds = remoteSession.remainingSeconds;
          _violationCount = remoteSession.violationCount;
        }
      } catch (e) {
        debugPrint('⚠️ Remote exam session check failed: $e');
        // Do not silently fall back to detached offline mode if session was already server-active
        if (_hasRemoteSession) {
          rethrow;
        }
      }
    }

    // 2. Hydrate saved drafts from local storage
    final restored = await _storageService.restoreSession();
    if (restored != null && !_isSubmitted) {
      _mcqAnswers.addAll(restored.mcqAnswers);
      _codingDrafts.addAll(restored.codingDrafts);
      _reviewFlags.addAll(restored.reviewFlagIds);
      if (_serverExpiresAt == null) {
        _remainingSeconds = restored.remainingSeconds;
      }
      if (!_hasRemoteSession) {
        _violationCount = restored.violationCount;
      }
      notifyListeners();
    }
  }

  Future<void> persistSession() async {
    if (!_isSubmitted) {
      await _storageService.saveSession(
        mcqAnswers: _mcqAnswers,
        codingDrafts: _codingDrafts,
        reviewFlagIds: _reviewFlags,
        remainingSeconds: _remainingSeconds,
        violationCount: _violationCount,
      );
    }
  }

  void _persistSession() {
    unawaited(persistSession());
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}
