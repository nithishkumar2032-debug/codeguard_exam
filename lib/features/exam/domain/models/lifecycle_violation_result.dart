import '../../../onboarding/models/candidate_details.dart';
import 'exam_result.dart';

/// Result returned from server-authoritative lifecycle violation recording.
class LifecycleViolationResult {
  final bool success;
  final int violationCount;
  final bool isTerminated;
  final bool warningRequired;
  final bool deduplicated;
  final String? reason;
  final ExamResult? result;

  const LifecycleViolationResult({
    required this.success,
    required this.violationCount,
    required this.isTerminated,
    this.warningRequired = false,
    this.deduplicated = false,
    this.reason,
    this.result,
  });

  factory LifecycleViolationResult.fromJson(
    Map<String, dynamic> json, [
    CandidateDetails? candidateDetails,
  ]) {
    ExamResult? result;
    if (json['result'] is Map) {
      result = ExamResult.fromJson(
        Map<String, dynamic>.from(json['result'] as Map),
        candidateDetails,
      );
    }

    return LifecycleViolationResult(
      success: json['success'] as bool? ?? false,
      violationCount: (json['violationCount'] ??
              json['violation_count'] as num?)
          ?.toInt() ??
          0,
      isTerminated: json['isTerminated'] as bool? ??
          json['is_terminated'] as bool? ??
          false,
      warningRequired: json['warningRequired'] as bool? ??
          json['warning_required'] as bool? ??
          false,
      deduplicated: json['deduplicated'] as bool? ?? false,
      reason: json['reason'] as String?,
      result: result,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'violationCount': violationCount,
        'isTerminated': isTerminated,
        'warningRequired': warningRequired,
        'deduplicated': deduplicated,
        'reason': reason,
        'result': result?.toJson(),
      };
}
