import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_service.dart';
import '../../onboarding/models/candidate_details.dart';
import '../domain/services/remote_exam_service.dart';

/// Supabase implementation of [RemoteExamService].
///
/// Communicates with PostgreSQL server-authoritative functions via authenticated RPC.
/// Features built-in in-flight request deduplication for session start/resume and submission.
class SupabaseRemoteExamService implements RemoteExamService {
  final SupabaseClient? _client;
  Future<RemoteExamSession?>? _inFlightSessionRequest;
  Future<SubmitSessionResult>? _inFlightSubmissionRequest;

  SupabaseRemoteExamService([this._client]);

  SupabaseClient? get client => _client ?? SupabaseService.instance.client;

  @override
  Future<RemoteExamSession?> startOrResumeSession({
    required String examId,
    required CandidateDetails candidateDetails,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('ℹ️ SupabaseRemoteExamService: Client uninitialized. Operating in standalone mode.');
      return null;
    }

    // In-flight request deduplication: prevent duplicate RPC calls from rapid taps or concurrent calls
    if (_inFlightSessionRequest != null) {
      debugPrint('ℹ️ SupabaseRemoteExamService: Reusing in-flight startOrResumeSession request.');
      return _inFlightSessionRequest!;
    }

    _inFlightSessionRequest = _executeStartOrResume(
      activeClient: activeClient,
      examId: examId,
      candidateDetails: candidateDetails,
    );

    try {
      return await _inFlightSessionRequest!;
    } finally {
      _inFlightSessionRequest = null;
    }
  }

  Future<RemoteExamSession> _executeStartOrResume({
    required SupabaseClient activeClient,
    required String examId,
    required CandidateDetails candidateDetails,
  }) async {
    try {
      final response = await activeClient.rpc(
        'start_or_resume_exam_session',
        params: {
          'p_exam_id': examId,
          'p_student_name': candidateDetails.studentName,
          'p_register_number': candidateDetails.registerNumber,
          'p_examination_name': candidateDetails.examinationName,
        },
      );

      if (response is Map) {
        return RemoteExamSession.fromJson(
          Map<String, dynamic>.from(response),
          candidateDetails,
        );
      }
      throw StateError('Unexpected response from start_or_resume_exam_session: $response');
    } catch (e, stack) {
      debugPrint('⚠️ SupabaseRemoteExamService: Failed to start/resume session: $e\n$stack');
      rethrow;
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
    final activeClient = client;
    if (activeClient == null) {
      return const SaveResponseResult(
        success: true,
        message: 'Standalone mode: Local persistence active',
      );
    }

    try {
      final response = await activeClient.rpc(
        'save_candidate_response',
        params: {
          'p_session_id': sessionId,
          'p_question_id': questionId,
          'p_selected_option': selectedOption,
          'p_is_marked': isMarked,
          'p_client_saved_at': (clientSavedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response is Map) {
        return SaveResponseResult.fromJson(Map<String, dynamic>.from(response));
      }
      return const SaveResponseResult(success: true);
    } catch (e, stack) {
      debugPrint('⚠️ SupabaseRemoteExamService: saveMcqResponse failed: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<SaveResponseResult> saveCodingDraft({
    required String sessionId,
    required String challengeId,
    required String codingDraft,
    bool isMarked = false,
    DateTime? clientSavedAt,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return const SaveResponseResult(
        success: true,
        message: 'Standalone mode: Local persistence active',
      );
    }

    try {
      final response = await activeClient.rpc(
        'save_candidate_coding_draft',
        params: {
          'p_session_id': sessionId,
          'p_challenge_id': challengeId,
          'p_coding_draft': codingDraft,
          'p_is_marked': isMarked,
          'p_client_saved_at': (clientSavedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response is Map) {
        return SaveResponseResult.fromJson(Map<String, dynamic>.from(response));
      }
      return const SaveResponseResult(success: true);
    } catch (e, stack) {
      debugPrint('⚠️ SupabaseRemoteExamService: saveCodingDraft failed: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<LifecycleViolationResult> recordLifecycleViolation({
    required String sessionId,
    required String signalType,
    DateTime? clientTimestamp,
    Map<String, dynamic>? metadata,
    CandidateDetails? candidateDetails,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return const LifecycleViolationResult(
        success: true,
        violationCount: 1,
        isTerminated: false,
      );
    }

    try {
      final response = await activeClient.rpc(
        'record_lifecycle_violation',
        params: {
          'p_session_id': sessionId,
          'p_signal_type': signalType,
          'p_client_timestamp':
              (clientTimestamp ?? DateTime.now()).toIso8601String(),
          'p_metadata': metadata ?? <String, dynamic>{},
        },
      );

      if (response is Map) {
        return LifecycleViolationResult.fromJson(
          Map<String, dynamic>.from(response),
          candidateDetails,
        );
      }
      return const LifecycleViolationResult(
        success: true,
        violationCount: 1,
        isTerminated: false,
      );
    } catch (e, stack) {
      debugPrint('⚠️ SupabaseRemoteExamService: recordLifecycleViolation failed: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<SubmitSessionResult> submitExamSession({
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      throw StateError('Cannot submit remote session: Supabase client uninitialized.');
    }

    // In-flight request deduplication: prevent concurrent submissions
    if (_inFlightSubmissionRequest != null) {
      debugPrint('ℹ️ SupabaseRemoteExamService: Reusing in-flight submitExamSession request.');
      return _inFlightSubmissionRequest!;
    }

    _inFlightSubmissionRequest = _executeSubmitExamSession(
      activeClient: activeClient,
      sessionId: sessionId,
      reason: reason,
      candidateDetails: candidateDetails,
    );

    try {
      return await _inFlightSubmissionRequest!;
    } finally {
      _inFlightSubmissionRequest = null;
    }
  }

  Future<SubmitSessionResult> _executeSubmitExamSession({
    required SupabaseClient activeClient,
    required String sessionId,
    required String reason,
    required CandidateDetails candidateDetails,
  }) async {
    try {
      final response = await activeClient.rpc(
        'submit_exam_session',
        params: {
          'p_session_id': sessionId,
          'p_reason': reason,
        },
      );

      if (response is Map) {
        return SubmitSessionResult.fromJson(
          Map<String, dynamic>.from(response),
          candidateDetails,
        );
      }
      throw StateError('Unexpected response from submit_exam_session: $response');
    } catch (e, stack) {
      debugPrint('⚠️ SupabaseRemoteExamService: submitExamSession failed: $e\n$stack');
      rethrow;
    }
  }
}
