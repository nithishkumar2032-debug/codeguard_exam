import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Central service managing the Supabase client lifecycle.
///
/// Ensures safe initialization:
/// - Connects to Supabase when `--dart-define` credentials are provided.
/// - Gracefully falls back to offline/standalone mode when unconfigured,
///   preventing crashes in unit/widget test runners and local development.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  SupabaseClient? _injectedClient;

  /// Whether Supabase has been initialized with active credentials.
  bool get isInitialized => _isInitialized || _injectedClient != null;

  /// The active [SupabaseClient], or null if unconfigured/offline.
  SupabaseClient? get client {
    if (_injectedClient != null) return _injectedClient;
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Initializes Supabase if credentials are provided.
  ///
  /// Safe to call during app startup in [main]. Will never throw an unhandled
  /// exception that prevents the Flutter app from launching.
  static Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    final targetUrl = url ?? SupabaseConfig.url;
    final targetAnonKey = anonKey ?? SupabaseConfig.anonKey;

    if (targetUrl.trim().isEmpty || targetAnonKey.trim().isEmpty) {
      debugPrint(
        'ℹ️ CodeGuard Exam: Supabase credentials not provided. '
        'Running in standalone/offline mode with local storage persistence.',
      );
      instance._isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: targetUrl.trim(),
        // ignore: deprecated_member_use
        anonKey: targetAnonKey.trim(),
        debug: kDebugMode,
      );
      instance._isInitialized = true;
      debugPrint('✅ CodeGuard Exam: Supabase initialized successfully.');
    } catch (e, stack) {
      debugPrint('⚠️ CodeGuard Exam: Failed to initialize Supabase: $e\n$stack');
      instance._isInitialized = false;
    }
  }

  /// Injects a custom or mock [SupabaseClient] for unit/widget testing.
  @visibleForTesting
  void injectClient(SupabaseClient? mockClient) {
    _injectedClient = mockClient;
    _isInitialized = mockClient != null;
  }

  /// Resets service state for tests.
  @visibleForTesting
  void reset() {
    _injectedClient = null;
    _isInitialized = false;
  }

  /// Currently authenticated user, or null if unauthenticated or in offline mode.
  User? get currentUser => client?.auth.currentUser;

  /// Returns true if an active authenticated session exists.
  bool get isAuthenticated => client?.auth.currentSession != null;

  /// Ensures an authenticated candidate session.
  ///
  /// - Reuses existing valid authenticated session if available.
  /// - Signs in anonymously when no active session exists.
  /// - Does NOT treat student name or register number as verified identity
  ///   (pseudonymous assessment identity only).
  /// - Returns null when running in unconfigured standalone/offline mode.
  Future<User?> ensureAuthenticatedCandidate({
    Map<String, dynamic>? metadata,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('ℹ️ CodeGuard Exam: Standalone mode active. Skipping remote authentication.');
      return null;
    }

    // Reuse existing valid session if still active
    final session = activeClient.auth.currentSession;
    if (session != null && !session.isExpired) {
      final user = activeClient.auth.currentUser;
      if (user != null) {
        debugPrint('ℹ️ CodeGuard Exam: Reusing active candidate session (${user.id}).');
        return user;
      }
    }

    try {
      final response = await activeClient.auth.signInAnonymously(data: metadata);
      debugPrint('✅ CodeGuard Exam: Anonymous candidate session established (${response.user?.id}).');
      return response.user;
    } on AuthException catch (e) {
      debugPrint('⚠️ CodeGuard Exam: AuthException during candidate sign-in: ${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('⚠️ CodeGuard Exam: Unexpected error during candidate sign-in: $e\n$stack');
      rethrow;
    }
  }

  /// Signs out of the current Supabase session.
  Future<void> signOut() async {
    final activeClient = client;
    if (activeClient != null) {
      try {
        await activeClient.auth.signOut();
      } catch (_) {}
    }
  }
}

