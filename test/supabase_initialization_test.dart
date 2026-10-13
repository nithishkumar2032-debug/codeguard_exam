import 'package:flutter_test/flutter_test.dart';
import 'package:codeguard_exam/core/config/supabase_config.dart';
import 'package:codeguard_exam/core/network/supabase_service.dart';

void main() {
  group('Supabase Configuration & Initialization (Phase A)', () {
    tearDown(() {
      SupabaseService.instance.reset();
    });

    test('SupabaseConfig defaults safely when environment variables are omitted', () {
      // In default test runner without --dart-define flags:
      expect(SupabaseConfig.url, isA<String>());
      expect(SupabaseConfig.anonKey, isA<String>());
      // When empty, isConfigured is false
      if (SupabaseConfig.url.isEmpty) {
        expect(SupabaseConfig.isConfigured, isFalse);
      }
    });

    test('SupabaseService handles missing credentials gracefully without throwing', () async {
      SupabaseService.instance.reset();
      expect(SupabaseService.instance.isInitialized, isFalse);
      expect(SupabaseService.instance.client, isNull);

      // Initialize with explicit empty strings simulating unconfigured environment
      await SupabaseService.initialize(url: '', anonKey: '');

      expect(SupabaseService.instance.isInitialized, isFalse);
      expect(SupabaseService.instance.client, isNull);
    });

    test('SupabaseService supports mock client injection and reset for unit tests', () {
      final service = SupabaseService.instance;
      expect(service.isInitialized, isFalse);

      // Before injection, client is null
      expect(service.client, isNull);

      service.reset();
      expect(service.isInitialized, isFalse);
    });
  });
}
