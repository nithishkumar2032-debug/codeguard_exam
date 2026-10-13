import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Data transfer object holding restored session state.
class PersistedExamSession {
  final Map<String, int> mcqAnswers;
  final Map<String, String> codingDrafts;
  final Set<String> reviewFlagIds;
  final int remainingSeconds;
  final DateTime savedAt;

  const PersistedExamSession({
    required this.mcqAnswers,
    required this.codingDrafts,
    required this.reviewFlagIds,
    required this.remainingSeconds,
    required this.savedAt,
  });
}

/// Storage contract for local draft persistence during examination attempts.
///
/// Security Notice: Browser local storage is inherently non-authoritative
/// and susceptible to client modification. It is employed here strictly
/// for candidate resilience against accidental page reloads.
/// No secrets or credentials are ever persisted here.
abstract class ExamStorageService {
  Future<void> saveSession({
    required Map<String, int> mcqAnswers,
    required Map<String, String> codingDrafts,
    required Set<String> reviewFlagIds,
    required int remainingSeconds,
  });

  Future<PersistedExamSession?> restoreSession();

  Future<void> clearSession();
}

/// SharedPreferences-based implementation of [ExamStorageService].
class SharedPrefsExamStorageService implements ExamStorageService {
  static const String _keyMcqAnswers = 'codeguard_mcq_answers_draft';
  static const String _keyCodingDrafts = 'codeguard_coding_drafts';
  static const String _keyReviewFlags = 'codeguard_review_flags';
  static const String _keyRemainingSeconds = 'codeguard_remaining_seconds';
  static const String _keySavedTimestamp = 'codeguard_saved_timestamp';

  final SharedPreferences? _prefsInstance;

  SharedPrefsExamStorageService([this._prefsInstance]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession({
    required Map<String, int> mcqAnswers,
    required Map<String, String> codingDrafts,
    required Set<String> reviewFlagIds,
    required int remainingSeconds,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyMcqAnswers, jsonEncode(mcqAnswers));
      await prefs.setString(_keyCodingDrafts, jsonEncode(codingDrafts));
      await prefs.setString(_keyReviewFlags, jsonEncode(reviewFlagIds.toList()));
      await prefs.setInt(_keyRemainingSeconds, remainingSeconds);
      await prefs.setString(_keySavedTimestamp, DateTime.now().toIso8601String());
    } catch (_) {
      // Persistence failures must not crash the exam experience
    }
  }

  @override
  Future<PersistedExamSession?> restoreSession() async {
    try {
      final prefs = await _getPrefs();
      final mcqJson = prefs.getString(_keyMcqAnswers);
      final codingJson = prefs.getString(_keyCodingDrafts);
      final reviewJson = prefs.getString(_keyReviewFlags);
      final seconds = prefs.getInt(_keyRemainingSeconds);
      final timestampStr = prefs.getString(_keySavedTimestamp);

      if (mcqJson == null &&
          codingJson == null &&
          reviewJson == null &&
          seconds == null) {
        return null;
      }

      // Safe decoding and type validation
      Map<String, int> mcqAnswers = {};
      if (mcqJson != null) {
        final decoded = jsonDecode(mcqJson);
        if (decoded is Map) {
          mcqAnswers = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
      }

      Map<String, String> codingDrafts = {};
      if (codingJson != null) {
        final decoded = jsonDecode(codingJson);
        if (decoded is Map) {
          codingDrafts = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }

      Set<String> reviewFlagIds = {};
      if (reviewJson != null) {
        final decoded = jsonDecode(reviewJson);
        if (decoded is List) {
          reviewFlagIds = decoded.map((e) => e.toString()).toSet();
        }
      }

      // Validate remaining seconds sanity (must be between 1 and 1800 seconds)
      int validatedSeconds = 1800;
      if (seconds != null && seconds > 0 && seconds <= 1800) {
        validatedSeconds = seconds;
      }

      DateTime savedAt = DateTime.now();
      if (timestampStr != null) {
        savedAt = DateTime.tryParse(timestampStr) ?? DateTime.now();
      }

      return PersistedExamSession(
        mcqAnswers: mcqAnswers,
        codingDrafts: codingDrafts,
        reviewFlagIds: reviewFlagIds,
        remainingSeconds: validatedSeconds,
        savedAt: savedAt,
      );
    } catch (_) {
      // Corrupt data safely ignored
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyMcqAnswers);
      await prefs.remove(_keyCodingDrafts);
      await prefs.remove(_keyReviewFlags);
      await prefs.remove(_keyRemainingSeconds);
      await prefs.remove(_keySavedTimestamp);
    } catch (_) {
      // Fail-safe cleanup
    }
  }
}
