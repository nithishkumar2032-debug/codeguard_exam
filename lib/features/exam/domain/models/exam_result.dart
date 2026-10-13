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

  Map<String, dynamic> toJson() => {
        'candidateDetails': {
          'studentName': candidateDetails.studentName,
          'registerNumber': candidateDetails.registerNumber,
          'examinationName': candidateDetails.examinationName,
        },
        'mcqScore': mcqScore,
        'maxMcqScore': maxMcqScore,
        'totalQuestions': totalQuestions,
        'answeredCount': answeredCount,
        'codingChallengesCount': codingChallengesCount,
        'codingAttemptedCount': codingAttemptedCount,
        'codingEvaluationStatus': codingEvaluationStatus,
        'submissionReason': submissionReason,
        'submittedAt': submittedAt.toIso8601String(),
        'isPreliminary': isPreliminary,
      };

  factory ExamResult.fromJson(
    Map<String, dynamic> json, [
    CandidateDetails? fallbackDetails,
  ]) {
    final candidateRaw = json['candidateDetails'] as Map?;
    final candidateDetails = fallbackDetails ??
        CandidateDetails(
          studentName: candidateRaw?['studentName'] as String? ??
              json['studentName'] as String? ??
              json['student_name'] as String? ??
              'Candidate',
          registerNumber: candidateRaw?['registerNumber'] as String? ??
              json['registerNumber'] as String? ??
              json['register_number'] as String? ??
              '',
          examinationName: candidateRaw?['examinationName'] as String? ??
              json['examinationName'] as String? ??
              json['examination_name'] as String? ??
              '',
        );

    final submittedAtStr = json['submittedAt'] as String? ??
        json['submitted_at'] as String? ??
        json['scored_at'] as String?;

    return ExamResult(
      candidateDetails: candidateDetails,
      mcqScore: (json['mcqScore'] ?? json['mcq_score'] as num?)?.toInt() ?? 0,
      maxMcqScore: (json['maxMcqScore'] ?? json['max_mcq_score'] as num?)?.toInt() ?? 10,
      totalQuestions: (json['totalQuestions'] ?? json['total_questions'] as num?)?.toInt() ?? 12,
      answeredCount: (json['answeredCount'] ?? json['answered_count'] as num?)?.toInt() ?? 0,
      codingChallengesCount: (json['codingChallengesCount'] ?? json['coding_challenges_count'] as num?)?.toInt() ?? 2,
      codingAttemptedCount: (json['codingAttemptedCount'] ?? json['coding_attempted_count'] as num?)?.toInt() ?? 0,
      codingEvaluationStatus: (json['codingEvaluationStatus'] ?? json['coding_evaluation_status'] as String?) ??
          'Submitted • Pending Automated Evaluation',
      submissionReason: (json['submissionReason'] ?? json['submission_reason'] as String?) ??
          'Completed',
      submittedAt: submittedAtStr != null
          ? DateTime.tryParse(submittedAtStr) ?? DateTime.now()
          : DateTime.now(),
      isPreliminary: (json['isPreliminary'] ?? json['is_preliminary'] as bool?) ?? true,
    );
  }
}

