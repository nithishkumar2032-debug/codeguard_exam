import '../../data/sample_coding_challenges.dart';
import '../../data/sample_mcqs.dart';
import '../../data/secret_exam_answer_keys.dart';
import '../../../onboarding/models/candidate_details.dart';
import '../models/exam_result.dart';

/// Service responsible for evaluating submitted exam answers.
///
/// Designed to run in isolation from question presentation. In future milestones,
/// this logic will transition directly to the backend.
class ExamScoringService {
  final Map<String, int> _answerKeys;

  ExamScoringService({Map<String, int>? answerKeys})
      : _answerKeys = answerKeys ?? SecretExamAnswerKeys.mcqAnswerKeys;

  /// Evaluates MCQ submissions against secret keys and packages the result.
  ExamResult scoreSubmission({
    required CandidateDetails candidateDetails,
    required Map<String, int> mcqAnswers,
    required Map<String, String> codingDrafts,
    required String submissionReason,
  }) {
    int score = 0;
    for (final entry in mcqAnswers.entries) {
      final questionId = entry.key;
      final selectedOption = entry.value;
      if (_answerKeys.containsKey(questionId) &&
          _answerKeys[questionId] == selectedOption) {
        score++;
      }
    }

    // Determine how many coding challenges were actually modified from starter code
    int attemptedCodingCount = 0;
    for (final challenge in SampleCodingChallenges.challenges) {
      final draft = codingDrafts[challenge.id];
      if (draft != null &&
          draft.trim().isNotEmpty &&
          draft.trim() != challenge.starterCode.trim()) {
        attemptedCodingCount++;
      }
    }

    return ExamResult(
      candidateDetails: candidateDetails,
      mcqScore: score,
      maxMcqScore: SampleMcqs.questions.length,
      totalQuestions:
          SampleMcqs.questions.length + SampleCodingChallenges.challenges.length,
      answeredCount: mcqAnswers.length,
      codingChallengesCount: SampleCodingChallenges.challenges.length,
      codingAttemptedCount: attemptedCodingCount,
      codingEvaluationStatus: attemptedCodingCount > 0
          ? 'Submitted ($attemptedCodingCount/${SampleCodingChallenges.challenges.length} attempted) • Pending Automated Test Suite Evaluation'
          : 'No coding solutions submitted',
      submissionReason: submissionReason,
      submittedAt: DateTime.now(),
      isPreliminary: true,
    );
  }
}
