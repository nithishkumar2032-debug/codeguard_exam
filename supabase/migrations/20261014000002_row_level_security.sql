-- ============================================================================
-- Migration: 20261014000002_row_level_security.sql
-- Description: Enable RLS on all tables and establish least-privilege policies.
-- ============================================================================

-- Enable RLS across all application and assessment tables
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcq_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcq_answer_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coding_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coding_test_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coding_hidden_test_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_mcq_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_coding_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_lifecycle_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_assessment_results ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 1. Policies for public.exams
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Active exams are viewable by all users" ON public.exams;
CREATE POLICY "Active exams are viewable by all users"
    ON public.exams
    FOR SELECT
    TO anon, authenticated
    USING (is_active = TRUE);

-- ----------------------------------------------------------------------------
-- 2. Policies for public.mcq_questions
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Questions for active exams are viewable by authenticated candidates" ON public.mcq_questions;
CREATE POLICY "Questions for active exams are viewable by authenticated candidates"
    ON public.mcq_questions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.exams e
            WHERE e.id = public.mcq_questions.exam_id
              AND e.is_active = TRUE
        )
    );

-- ----------------------------------------------------------------------------
-- 3. Policies for public.mcq_answer_keys (PROTECTED / ZERO ACCESS)
-- Note: With RLS enabled and NO policies declared, all SELECT, INSERT, UPDATE,
-- and DELETE operations from ordinary candidates (anon & authenticated) are
-- strictly DENIED by PostgreSQL. Only SECURITY DEFINER functions can read this.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 4. Policies for public.coding_challenges
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Coding challenges for active exams are viewable by authenticated candidates" ON public.coding_challenges;
CREATE POLICY "Coding challenges for active exams are viewable by authenticated candidates"
    ON public.coding_challenges
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.exams e
            WHERE e.id = public.coding_challenges.exam_id
              AND e.is_active = TRUE
        )
    );

-- ----------------------------------------------------------------------------
-- 5. Policies for public.coding_test_cases (Public sample test cases)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public sample test cases viewable by authenticated candidates" ON public.coding_test_cases;
CREATE POLICY "Public sample test cases viewable by authenticated candidates"
    ON public.coding_test_cases
    FOR SELECT
    TO authenticated
    USING (TRUE);

-- ----------------------------------------------------------------------------
-- 6. Policies for public.coding_hidden_test_cases (PROTECTED / ZERO ACCESS)
-- Note: With RLS enabled and NO policies declared, access is strictly DENIED
-- to all client roles. Hidden tests are used exclusively by server-side evaluation.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 7. Policies for public.candidate_exam_sessions
-- Candidates can view their own sessions. All mutations are strictly routed
-- through server-authoritative functions to prevent client manipulation.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Candidates can view their own sessions" ON public.candidate_exam_sessions;
CREATE POLICY "Candidates can view their own sessions"
    ON public.candidate_exam_sessions
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 8. Policies for public.candidate_mcq_responses
-- Candidates can read and write only their own answers while their session
-- is in-progress and within valid server expiry.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Candidates can view their own MCQ responses" ON public.candidate_mcq_responses;
CREATE POLICY "Candidates can view their own MCQ responses"
    ON public.candidate_mcq_responses
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = public.candidate_mcq_responses.session_id
              AND s.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Candidates can insert MCQ responses during active session" ON public.candidate_mcq_responses;
CREATE POLICY "Candidates can insert MCQ responses during active session"
    ON public.candidate_mcq_responses
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    );

DROP POLICY IF EXISTS "Candidates can update MCQ responses during active session" ON public.candidate_mcq_responses;
CREATE POLICY "Candidates can update MCQ responses during active session"
    ON public.candidate_mcq_responses
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = public.candidate_mcq_responses.session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    );

-- ----------------------------------------------------------------------------
-- 9. Policies for public.candidate_coding_drafts
-- Candidates can read and write only their own drafts while their session
-- is in-progress and within valid server expiry.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Candidates can view their own coding drafts" ON public.candidate_coding_drafts;
CREATE POLICY "Candidates can view their own coding drafts"
    ON public.candidate_coding_drafts
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = public.candidate_coding_drafts.session_id
              AND s.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Candidates can insert coding drafts during active session" ON public.candidate_coding_drafts;
CREATE POLICY "Candidates can insert coding drafts during active session"
    ON public.candidate_coding_drafts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    );

DROP POLICY IF EXISTS "Candidates can update coding drafts during active session" ON public.candidate_coding_drafts;
CREATE POLICY "Candidates can update coding drafts during active session"
    ON public.candidate_coding_drafts
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = public.candidate_coding_drafts.session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = session_id
              AND s.user_id = auth.uid()
              AND s.status = 'in_progress'
              AND NOW() <= s.expires_at
        )
    );

-- ----------------------------------------------------------------------------
-- 10. Policies for public.candidate_lifecycle_violations
-- Candidates can inspect their own violation history. Creation is strictly
-- controlled via authoritative database functions.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Candidates can view their own violations" ON public.candidate_lifecycle_violations;
CREATE POLICY "Candidates can view their own violations"
    ON public.candidate_lifecycle_violations
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.candidate_exam_sessions s
            WHERE s.id = public.candidate_lifecycle_violations.session_id
              AND s.user_id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- 11. Policies for public.candidate_assessment_results
-- Official scores can be read only by the owning candidate. Inserting and
-- altering scores directly from client-side requests is strictly forbidden.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Candidates can view their own results" ON public.candidate_assessment_results;
CREATE POLICY "Candidates can view their own results"
    ON public.candidate_assessment_results
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());
