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
import '../../../onboarding/models/candidate_details.dart';

/// Central controller managing the entire examination lifecycle.
///
/// Responsibilities:
/// - Precise countdown timer execution without multiple overlapping timers.
/// - Question indexing, selection, navigation, and review flagging.
/// - Idempotent, duplicate-guarded submission (auto on timeout or candidate manual).
/// - Draft persistence for refresh recovery.
class ExamController extends ChangeNotifier {
  final CandidateDetails candidateDetails;
  final ExamScoringService _scoringService;
  final ExamStorageService _storageService;
  final CodeExecutionService codeExecutionService;

  final List<McqQuestion> mcqs;
  final List<CodingChallenge> codingChallenges;

  int _currentIndex = 0;
  int _remainingSeconds = 30 * 60; // 30 minutes countdown = 1800 seconds
  Timer? _timer;
  bool _isSubmitted = false;
  ExamResult? _examResult;

  final Map<String, int> _mcqAnswers = {};
  final Map<String, String> _codingDrafts = {};
  final Set<String> _reviewFlags = {};

  ExamController({
    required this.candidateDetails,
    ExamScoringService? scoringService,
    ExamStorageService? storageService,
    CodeExecutionService? codeExecutionService,
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
  bool get isSubmitted => _isSubmitted;
  ExamResult? get examResult => _examResult;
  bool get isTimerRunning => _timer != null && _timer!.isActive;

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
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();

        // Periodically save state to local storage every 15 seconds
        if (_remainingSeconds % 15 == 0) {
          _persistSession();
        }
      } else {
        // Automatically submit when the timer reaches zero
        timer.cancel();
        _timer = null;
        submitExam(reason: 'Timer expired (Auto-submitted)');
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
  }

  void updateCodingDraft(String challengeId, String code) {
    if (_isSubmitted) return;
    _codingDrafts[challengeId] = code;
    notifyListeners();
    _persistSession();
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

    // Score MCQs using separate scoring service
    _examResult = _scoringService.scoreSubmission(
      candidateDetails: candidateDetails,
      mcqAnswers: _mcqAnswers,
      codingDrafts: _codingDrafts,
      submissionReason: reason,
    );

    // Clear local draft state after final submission
    _storageService.clearSession();

    notifyListeners();
    return _examResult!;
  }

  // --- Persistence Recovery ---

  Future<void> restoreSessionIfAvailable() async {
    final restored = await _storageService.restoreSession();
    if (restored != null && !_isSubmitted) {
      _mcqAnswers.addAll(restored.mcqAnswers);
      _codingDrafts.addAll(restored.codingDrafts);
      _reviewFlags.addAll(restored.reviewFlagIds);
      _remainingSeconds = restored.remainingSeconds;
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
