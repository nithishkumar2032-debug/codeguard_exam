import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:codeguard_exam/features/exam/data/sample_mcqs.dart';
import 'package:codeguard_exam/features/exam/data/sample_coding_challenges.dart';
import 'package:codeguard_exam/features/exam/data/secret_exam_answer_keys.dart';

void main() {
  group('Supabase Database Schema & RLS Static Contract Verifications (Phase B)', () {
    late String schemaSql;
    late String rlsSql;
    late String functionsSql;
    late String seedSql;

    setUpAll(() {
      final migrationDir = Directory('supabase/migrations');
      expect(migrationDir.existsSync(), isTrue, reason: 'supabase/migrations directory must exist');

      final files = migrationDir.listSync().whereType<File>().toList();
      expect(files.length, greaterThanOrEqualTo(4));

      schemaSql = File('supabase/migrations/20261014000001_initial_exam_schema.sql').readAsStringSync();
      rlsSql = File('supabase/migrations/20261014000002_row_level_security.sql').readAsStringSync();
      functionsSql = File('supabase/migrations/20261014000003_server_authoritative_functions.sql').readAsStringSync();
      seedSql = File('supabase/migrations/20261014000004_seed_assessment_data.sql').readAsStringSync();
    });

    test('All 11 core tables are declared with constraints and indexes', () {
      final requiredTables = [
        'public.exams',
        'public.mcq_questions',
        'public.mcq_answer_keys',
        'public.coding_challenges',
        'public.coding_test_cases',
        'public.coding_hidden_test_cases',
        'public.candidate_exam_sessions',
        'public.candidate_mcq_responses',
        'public.candidate_coding_drafts',
        'public.candidate_lifecycle_violations',
        'public.candidate_assessment_results',
      ];

      for (final table in requiredTables) {
        expect(
          schemaSql.contains('CREATE TABLE IF NOT EXISTS $table'),
          isTrue,
          reason: '$table must be created in initial schema',
        );
      }

      // Check key constraints
      expect(schemaSql.contains('CHECK (duration_seconds > 0 AND duration_seconds <= 86400)'), isTrue);
      expect(schemaSql.contains('CHECK (status IN (\'in_progress\', \'submitted\', \'terminated_lifecycle\', \'expired\'))'), isTrue);
      expect(schemaSql.contains('CHECK (violation_count >= 0 AND violation_count <= 2)'), isTrue);
      expect(schemaSql.contains('uq_candidate_session_per_exam UNIQUE (user_id, exam_id)'), isTrue);
    });

    test('Row Level Security is explicitly enabled on all 11 tables', () {
      final tablesToProtect = [
        'public.exams',
        'public.mcq_questions',
        'public.mcq_answer_keys',
        'public.coding_challenges',
        'public.coding_test_cases',
        'public.coding_hidden_test_cases',
        'public.candidate_exam_sessions',
        'public.candidate_mcq_responses',
        'public.candidate_coding_drafts',
        'public.candidate_lifecycle_violations',
        'public.candidate_assessment_results',
      ];

      for (final table in tablesToProtect) {
        expect(
          rlsSql.contains('ALTER TABLE $table ENABLE ROW LEVEL SECURITY;'),
          isTrue,
          reason: 'RLS must be enabled on $table',
        );
      }
    });

    test('Protected answer keys and hidden tests have zero client-accessible policies', () {
      // In PostgreSQL RLS, if RLS is enabled and NO policies exist for a table,
      // all SELECT/INSERT/UPDATE/DELETE queries from anon and authenticated are rejected by default.
      expect(
        rlsSql.contains('CREATE POLICY') && rlsSql.contains('ON public.mcq_answer_keys'),
        isFalse,
        reason: 'Zero policies must be granted on public.mcq_answer_keys to ensure total access denial to clients',
      );

      expect(
        rlsSql.contains('CREATE POLICY') && rlsSql.contains('ON public.coding_hidden_test_cases'),
        isFalse,
        reason: 'Zero policies must be granted on public.coding_hidden_test_cases',
      );
    });

    test('Candidate policies strictly enforce user isolation (user_id = auth.uid())', () {
      expect(rlsSql.contains('USING (user_id = auth.uid())'), isTrue);
      expect(rlsSql.contains('AND s.user_id = auth.uid()'), isTrue);
      expect(rlsSql.contains('AND s.status = \'in_progress\''), isTrue);
      expect(rlsSql.contains('AND NOW() <= s.expires_at'), isTrue);
    });

    test('Server-authoritative functions enforce SECURITY DEFINER, fixed search_path, and revoke public execution', () {
      final requiredFunctions = [
        '_finalize_and_score_session',
        'start_or_resume_exam_session',
        'save_candidate_response',
        'save_candidate_coding_draft',
        'record_lifecycle_violation',
        'submit_exam_session',
      ];

      for (final fn in requiredFunctions) {
        expect(functionsSql.contains('FUNCTION public.$fn'), isTrue, reason: 'Function $fn must be declared');
      }

      // Security hardening checks
      final securityDefinerMatches = 'SECURITY DEFINER'.allMatches(functionsSql).length;
      expect(securityDefinerMatches, greaterThanOrEqualTo(6), reason: 'All functions must be SECURITY DEFINER');

      final searchPathMatches = 'SET search_path = public, pg_temp'.allMatches(functionsSql).length;
      expect(searchPathMatches, greaterThanOrEqualTo(6), reason: 'All functions must fix search_path to prevent hijacking');

      expect(functionsSql.contains('REVOKE EXECUTE ON FUNCTION public.start_or_resume_exam_session'), isTrue);
      expect(functionsSql.contains('REVOKE EXECUTE ON FUNCTION public.record_lifecycle_violation'), isTrue);
      expect(functionsSql.contains('REVOKE EXECUTE ON FUNCTION public.submit_exam_session'), isTrue);
      expect(functionsSql.contains('GRANT EXECUTE ON FUNCTION public.submit_exam_session(UUID, TEXT) TO authenticated'), isTrue);
    });

    test('Database transaction row locking (FOR UPDATE) is used for race-condition prevention', () {
      final forUpdateMatches = 'FOR UPDATE'.allMatches(functionsSql).length;
      expect(
        forUpdateMatches,
        greaterThanOrEqualTo(5),
        reason: 'Functions must acquire FOR UPDATE row locks to serialize concurrent requests',
      );
    });

    test('Strike 2 triggers atomic auto-submission and termination in SQL', () {
      expect(functionsSql.contains('status = \'terminated_lifecycle\''), isTrue);
      expect(functionsSql.contains('submission_reason = \'Second lifecycle violation (Integrity auto-submission)\''), isTrue);
      expect(functionsSql.contains('v_result := public._finalize_and_score_session'), isTrue);
    });

    test('Duplicate submission prevention returns existing outcome idempotently', () {
      expect(functionsSql.contains('IF v_session.status IN (\'submitted\', \'terminated_lifecycle\', \'expired\') THEN'), isTrue);
      expect(functionsSql.contains('\'alreadySubmitted\', TRUE'), isTrue);
    });

    test('Seed data matches exact 10 MCQs and 2 coding challenges from existing domain data', () {
      expect(seedSql.contains('cs301_dsa_final'), isTrue);
      expect(seedSql.contains('mcq_1'), isTrue);
      expect(seedSql.contains('mcq_10'), isTrue);
      expect(seedSql.contains('code_1'), isTrue);
      expect(seedSql.contains('code_2'), isTrue);

      // Verify answers in seed match SecretExamAnswerKeys
      for (final entry in SecretExamAnswerKeys.mcqAnswerKeys.entries) {
        expect(
          seedSql.contains("('${entry.key}', ${entry.value},"),
          isTrue,
          reason: 'Answer key for ${entry.key} must be ${entry.value}',
        );
      }

      // Verify questions count
      expect(SampleMcqs.questions.length, 10);
      expect(SampleCodingChallenges.challenges.length, 2);
    });

    test('Client-facing models never leak answer keys or hidden test cases in JSON serialization', () {
      final sampleMcq = SampleMcqs.questions.first;
      final mcqJson = sampleMcq.toJson();
      expect(mcqJson.containsKey('correctOption'), isFalse);
      expect(mcqJson.containsKey('correct_option_index'), isFalse);
      expect(mcqJson.containsKey('answerKey'), isFalse);

      final sampleChallenge = SampleCodingChallenges.challenges.first;
      final challengeJson = sampleChallenge.toJson();
      expect(challengeJson.containsKey('hiddenTests'), isFalse);
      expect(challengeJson.containsKey('hiddenTestCases'), isFalse);
    });
  });
}
