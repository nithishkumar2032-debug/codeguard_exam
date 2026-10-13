import '../../../onboarding/models/candidate_details.dart';
import 'exam_result.dart';

/// Immutable domain model representing a server-authoritative candidate exam session.
class RemoteExamSession {
  final String sessionId;
  final String status; // 'in_progress', 'submitted', 'terminated_lifecycle', 'expired'
  final bool isFinished;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? serverTime;
  final int remainingSeconds;
  final int violationCount;
  final String? submissionReason;
  final ExamResult? result;

  const RemoteExamSession({
    required this.sessionId,
    required this.status,
    required this.isFinished,
    this.startedAt,
    this.expiresAt,
    this.serverTime,
    required this.remainingSeconds,
    required this.violationCount,
    this.submissionReason,
    this.result,
  });

  bool get isInProgress => status == 'in_progress' && !isFinished;
  bool get isExpired => status == 'expired';
  bool get isTerminated => status == 'terminated_lifecycle';
  bool get isSubmitted => status == 'submitted';

  factory RemoteExamSession.fromJson(
    Map<String, dynamic> json,
    CandidateDetails candidateDetails,
  ) {
    final status = (json['status'] as String? ?? 'in_progress').toLowerCase();
    final isFinished = (json['isFinished'] as bool?) ??
        (status == 'submitted' || status == 'terminated_lifecycle' || status == 'expired');

    final startedAtStr = json['startedAt'] as String? ?? json['started_at'] as String?;
    final expiresAtStr = json['expiresAt'] as String? ?? json['expires_at'] as String?;
    final serverTimeStr = json['serverTime'] as String? ?? json['server_time'] as String?;

    ExamResult? result;
    if (json['result'] is Map) {
      result = ExamResult.fromJson(
        Map<String, dynamic>.from(json['result'] as Map),
        candidateDetails,
      );
    }

    return RemoteExamSession(
      sessionId: json['sessionId'] as String? ?? json['session_id'] as String? ?? '',
      status: status,
      isFinished: isFinished,
      startedAt: startedAtStr != null ? DateTime.tryParse(startedAtStr) : null,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      serverTime: serverTimeStr != null ? DateTime.tryParse(serverTimeStr) : null,
      remainingSeconds: (json['remainingSeconds'] ?? json['remaining_seconds'] as num?)?.toInt() ?? 1800,
      violationCount: (json['violationCount'] ?? json['violation_count'] as num?)?.toInt() ?? 0,
      submissionReason: json['submissionReason'] as String? ?? json['submission_reason'] as String?,
      result: result,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'status': status,
        'isFinished': isFinished,
        'startedAt': startedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'serverTime': serverTime?.toIso8601String(),
        'remainingSeconds': remainingSeconds,
        'violationCount': violationCount,
        'submissionReason': submissionReason,
        'result': result?.toJson(),
      };
}
