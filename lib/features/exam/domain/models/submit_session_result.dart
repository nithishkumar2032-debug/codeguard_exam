import '../../../onboarding/models/candidate_details.dart';
import 'exam_result.dart';

/// Result returned from server-authoritative exam submission.
class SubmitSessionResult {
  final bool success;
  final bool alreadySubmitted;
  final String status;
  final String submissionReason;
  final ExamResult? result;

  const SubmitSessionResult({
    required this.success,
    required this.alreadySubmitted,
    required this.status,
    required this.submissionReason,
    this.result,
  });

  factory SubmitSessionResult.fromJson(
    Map<String, dynamic> json,
    CandidateDetails candidateDetails,
  ) {
    ExamResult? result;
    if (json['result'] is Map) {
      result = ExamResult.fromJson(
        Map<String, dynamic>.from(json['result'] as Map),
        candidateDetails,
      );
    }

    return SubmitSessionResult(
      success: json['success'] as bool? ?? false,
      alreadySubmitted: json['alreadySubmitted'] as bool? ??
          json['already_submitted'] as bool? ??
          false,
      status: json['status'] as String? ?? 'submitted',
      submissionReason: json['submissionReason'] as String? ??
          json['submission_reason'] as String? ??
          'Completed',
      result: result,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'alreadySubmitted': alreadySubmitted,
        'status': status,
        'submissionReason': submissionReason,
        'result': result?.toJson(),
      };
}
