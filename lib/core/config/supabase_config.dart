/// Compile-time configuration for Supabase integration.
///
/// SECURITY RULES & MANDATES:
/// 1. Only the publishable/anon key is exposed here. It is safe for client-side
///    distribution because all tables are protected by PostgreSQL Row Level Security (RLS).
/// 2. NEVER place the `service_role` key, database passwords, or any server secrets
///    in this file, in `lib/`, `test/`, build artifacts, or client configuration.
/// 3. Pass keys at build/run time via `--dart-define`:
///    `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract class SupabaseConfig {
  /// The public Supabase project URL (e.g. `https://xyzcompany.supabase.co`).
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lhhhyhwyqzdosoqktwjw.supabase.co',
  );

  /// The public Supabase anonymous key (publishable).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoaGh5aHd5cXpkb3NvcWt0d2p3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5MTI4OTQsImV4cCI6MjEwNzQ4ODg5NH0.Mx4ArTw6_za5OHYJRjM0tVuKZ6Y9YjMV0xLPHCYtSQs',
  );

  /// Returns true if both URL and publishable key are configured via `--dart-define`.
  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
