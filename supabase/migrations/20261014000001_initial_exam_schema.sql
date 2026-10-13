-- ============================================================================
-- Migration: 20261014000001_initial_exam_schema.sql
-- Description: Core tables, foreign keys, check constraints, and indexes for CodeGuard Exam.
-- ============================================================================

-- Ensure pgcrypto extension is available for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. Table: exams
-- Stores top-level examination configurations and time limits.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exams (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    duration_seconds INTEGER NOT NULL DEFAULT 1800 CHECK (duration_seconds > 0 AND duration_seconds <= 86400),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. Table: mcq_questions
-- Candidate-visible multiple-choice questions. Answer keys are strictly excluded.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mcq_questions (
    id TEXT PRIMARY KEY,
    exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL CHECK (question_number > 0),
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_mcq_exam_question_number UNIQUE (exam_id, question_number)
);

CREATE INDEX IF NOT EXISTS idx_mcq_questions_exam_id ON public.mcq_questions(exam_id);

-- ----------------------------------------------------------------------------
-- 3. Table: mcq_answer_keys (SECRET / PROTECTED)
-- Holds the authoritative correct option index.
-- NEVER exposed to client queries via Row Level Security.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mcq_answer_keys (
    question_id TEXT PRIMARY KEY REFERENCES public.mcq_questions(id) ON DELETE CASCADE,
    correct_option_index INTEGER NOT NULL CHECK (correct_option_index >= 0 AND correct_option_index <= 3),
    explanation TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. Table: coding_challenges
-- Candidate-visible coding challenge specifications and starter templates.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coding_challenges (
    id TEXT PRIMARY KEY,
    exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
    challenge_number INTEGER NOT NULL CHECK (challenge_number > 0),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'JavaScript',
    starter_code TEXT NOT NULL,
    sample_input TEXT NOT NULL,
    sample_output TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_coding_exam_challenge_number UNIQUE (exam_id, challenge_number)
);

CREATE INDEX IF NOT EXISTS idx_coding_challenges_exam_id ON public.coding_challenges(exam_id);

-- ----------------------------------------------------------------------------
-- 5. Table: coding_test_cases
-- Public sample test cases displayed to candidates in their static/test editor.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coding_test_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id TEXT NOT NULL REFERENCES public.coding_challenges(id) ON DELETE CASCADE,
    input TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    test_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coding_test_cases_challenge_id ON public.coding_test_cases(challenge_id);

-- ----------------------------------------------------------------------------
-- 6. Table: coding_hidden_test_cases (SECRET / PROTECTED)
-- Hidden test cases used strictly by server-side evaluation.
-- NEVER exposed to client queries via Row Level Security.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coding_hidden_test_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id TEXT NOT NULL REFERENCES public.coding_challenges(id) ON DELETE CASCADE,
    input TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    test_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coding_hidden_test_cases_challenge_id ON public.coding_hidden_test_cases(challenge_id);

-- ----------------------------------------------------------------------------
-- 7. Table: candidate_exam_sessions
-- Tracks official candidate attempts, server-authoritative timestamps, and integrity status.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_exam_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_id TEXT NOT NULL REFERENCES public.exams(id),
    student_name TEXT NOT NULL,
    register_number TEXT NOT NULL,
    examination_name TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    submitted_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'terminated_lifecycle', 'expired')),
    submission_reason TEXT,
    violation_count INTEGER NOT NULL DEFAULT 0 CHECK (violation_count >= 0 AND violation_count <= 2),
    last_heartbeat_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_candidate_session_per_exam UNIQUE (user_id, exam_id)
);

CREATE INDEX IF NOT EXISTS idx_candidate_sessions_user_id ON public.candidate_exam_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_sessions_exam_id ON public.candidate_exam_sessions(exam_id);
CREATE INDEX IF NOT EXISTS idx_candidate_sessions_status ON public.candidate_exam_sessions(status);
CREATE INDEX IF NOT EXISTS idx_candidate_sessions_expires_at ON public.candidate_exam_sessions(expires_at);

-- ----------------------------------------------------------------------------
-- 8. Table: candidate_mcq_responses
-- Stores candidate MCQ answers and review flags with client timestamp conflict tracking.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_mcq_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.candidate_exam_sessions(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL REFERENCES public.mcq_questions(id) ON DELETE CASCADE,
    selected_option_index INTEGER CHECK (selected_option_index >= 0 AND selected_option_index <= 3),
    is_marked_for_review BOOLEAN NOT NULL DEFAULT FALSE,
    client_saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_session_mcq_question UNIQUE (session_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_candidate_mcq_responses_session_id ON public.candidate_mcq_responses(session_id);

-- ----------------------------------------------------------------------------
-- 9. Table: candidate_coding_drafts
-- Stores candidate code implementations and review flags.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_coding_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.candidate_exam_sessions(id) ON DELETE CASCADE,
    challenge_id TEXT NOT NULL REFERENCES public.coding_challenges(id) ON DELETE CASCADE,
    coding_draft TEXT NOT NULL,
    is_marked_for_review BOOLEAN NOT NULL DEFAULT FALSE,
    client_saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_session_coding_challenge UNIQUE (session_id, challenge_id)
);

CREATE INDEX IF NOT EXISTS idx_candidate_coding_drafts_session_id ON public.candidate_coding_drafts(session_id);

-- ----------------------------------------------------------------------------
-- 10. Table: candidate_lifecycle_violations
-- Immutable append-only audit trail for browser tab/focus infractions.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_lifecycle_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.candidate_exam_sessions(id) ON DELETE CASCADE,
    violation_number INTEGER NOT NULL CHECK (violation_number IN (1, 2)),
    signal_type TEXT NOT NULL CHECK (signal_type IN ('documentHidden', 'windowBlur')),
    client_timestamp TIMESTAMPTZ,
    server_recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_session_violation_step UNIQUE (session_id, violation_number)
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_violations_session_id ON public.candidate_lifecycle_violations(session_id);

-- ----------------------------------------------------------------------------
-- 11. Table: candidate_assessment_results
-- Server-calculated outcomes produced upon exam finalization.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidate_assessment_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.candidate_exam_sessions(id) ON DELETE CASCADE UNIQUE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mcq_score INTEGER NOT NULL CHECK (mcq_score >= 0 AND mcq_score <= 10),
    max_mcq_score INTEGER NOT NULL DEFAULT 10,
    answered_count INTEGER NOT NULL DEFAULT 0,
    coding_attempted_count INTEGER NOT NULL DEFAULT 0,
    coding_challenges_count INTEGER NOT NULL DEFAULT 2,
    coding_evaluation_status TEXT NOT NULL,
    submission_reason TEXT NOT NULL,
    is_preliminary BOOLEAN NOT NULL DEFAULT TRUE,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_assessment_results_user_id ON public.candidate_assessment_results(user_id);
CREATE INDEX IF NOT EXISTS idx_assessment_results_session_id ON public.candidate_assessment_results(session_id);
