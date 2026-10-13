import '../../../onboarding/models/candidate_details.dart';

/// Immutable model capturing the outcome of an exam submission.
class ExamResult {
  final CandidateDetails candidateDetails;
  final int mcqScore;
  final int maxMcqScore;
  final int totalQuestions;
  final int answeredCount;
  final int codingChallengesCount;
  final int codingAttemptedCount;
  final String codingEvaluationStatus;
  final String submissionReason;
  final DateTime submittedAt;
  final bool isPreliminary;

  const ExamResult({
    required this.candidateDetails,
    required this.mcqScore,
    required this.maxMcqScore,
    required this.totalQuestions,
    required this.answeredCount,
    required this.codingChallengesCount,
    required this.codingAttemptedCount,
    required this.codingEvaluationStatus,
    required this.submissionReason,
    required this.submittedAt,
    this.isPreliminary = true,
  });

  double get mcqPercentage =>
      maxMcqScore > 0 ? (mcqScore / maxMcqScore) * 100 : 0.0;
}
