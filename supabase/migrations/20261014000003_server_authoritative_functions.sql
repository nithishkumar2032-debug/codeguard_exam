-- ============================================================================
-- Migration: 20261014000003_server_authoritative_functions.sql
-- Description: Server-authoritative stored procedures with transaction row-locking,
--              atomic lifecycle termination, duplicate prevention, and score computation.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Internal Helper: _finalize_and_score_session
-- Scores MCQs and commits assessment results. Must be called within a locked session transaction.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._finalize_and_score_session(
    p_session public.candidate_exam_sessions,
    p_submission_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_mcq_score INTEGER := 0;
    v_max_mcq_score INTEGER := 0;
    v_answered_count INTEGER := 0;
    v_coding_challenges_count INTEGER := 0;
    v_coding_attempted_count INTEGER := 0;
    v_coding_status TEXT;
    v_result_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Calculate MCQ score against protected answer keys
    SELECT
        COUNT(CASE WHEN r.selected_option_index = k.correct_option_index THEN 1 END),
        COUNT(r.selected_option_index)
    INTO
        v_mcq_score,
        v_answered_count
    FROM public.candidate_mcq_responses r
    JOIN public.mcq_answer_keys k ON k.question_id = r.question_id
    WHERE r.session_id = p_session.id;

    -- Total MCQ count for exam
    SELECT COUNT(*) INTO v_max_mcq_score
    FROM public.mcq_questions
    WHERE exam_id = p_session.exam_id;

    -- 2. Calculate Coding Challenge attempted count
    SELECT COUNT(*) INTO v_coding_challenges_count
    FROM public.coding_challenges
    WHERE exam_id = p_session.exam_id;

    SELECT COUNT(*) INTO v_coding_attempted_count
    FROM public.candidate_coding_drafts d
    JOIN public.coding_challenges c ON c.id = d.challenge_id
    WHERE d.session_id = p_session.id
      AND LENGTH(TRIM(d.coding_draft)) > 0
      AND TRIM(d.coding_draft) <> TRIM(c.starter_code);

    -- Format coding evaluation status
    IF v_coding_attempted_count > 0 THEN
        v_coding_status := 'Submitted (' || v_coding_attempted_count || '/' || v_coding_challenges_count || ' attempted) • Pending Automated Test Suite Evaluation';
    ELSE
        v_coding_status := 'No coding solutions submitted';
    END IF;

    -- 3. Upsert into candidate_assessment_results
    INSERT INTO public.candidate_assessment_results (
        session_id,
        user_id,
        mcq_score,
        max_mcq_score,
        answered_count,
        coding_attempted_count,
        coding_challenges_count,
        coding_evaluation_status,
        submission_reason,
        is_preliminary,
        scored_at
    )
    VALUES (
        p_session.id,
        p_session.user_id,
        v_mcq_score,
        v_max_mcq_score,
        v_answered_count,
        v_coding_attempted_count,
        v_coding_challenges_count,
        v_coding_status,
        p_submission_reason,
        TRUE,
        NOW()
    )
    ON CONFLICT (session_id) DO UPDATE SET
        mcq_score = EXCLUDED.mcq_score,
        max_mcq_score = EXCLUDED.max_mcq_score,
        answered_count = EXCLUDED.answered_count,
        coding_attempted_count = EXCLUDED.coding_attempted_count,
        coding_challenges_count = EXCLUDED.coding_challenges_count,
        coding_evaluation_status = EXCLUDED.coding_evaluation_status,
        submission_reason = EXCLUDED.submission_reason,
        scored_at = NOW()
    RETURNING id INTO v_result_id;

    -- 4. Build returned result object
    v_result := jsonb_build_object(
        'id', v_result_id,
        'sessionId', p_session.id,
        'studentName', p_session.student_name,
        'registerNumber', p_session.register_number,
        'examinationName', p_session.examination_name,
        'mcqScore', v_mcq_score,
        'maxMcqScore', v_max_mcq_score,
        'totalQuestions', v_max_mcq_score + v_coding_challenges_count,
        'answeredCount', v_answered_count,
        'codingChallengesCount', v_coding_challenges_count,
        'codingAttemptedCount', v_coding_attempted_count,
        'codingEvaluationStatus', v_coding_status,
        'submissionReason', p_submission_reason,
        'isPreliminary', TRUE,
        'submittedAt', NOW()
    );

    RETURN v_result;
END;
$$;

-- ----------------------------------------------------------------------------
-- 1. Function: start_or_resume_exam_session
-- Initiates an exam attempt or safely resumes an active one, computing exact remaining time.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_or_resume_exam_session(
    p_exam_id TEXT,
    p_student_name TEXT,
    p_register_number TEXT,
    p_examination_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_exam public.exams;
    v_session public.candidate_exam_sessions;
    v_now TIMESTAMPTZ := NOW();
    v_expires_at TIMESTAMPTZ;
    v_remaining_seconds INTEGER;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to start or resume an examination session';
    END IF;

    -- Fetch exam definition
    SELECT * INTO v_exam
    FROM public.exams
    WHERE id = p_exam_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Examination % not found or is currently inactive', p_exam_id;
    END IF;

    -- Check for existing session with row lock
    SELECT * INTO v_session
    FROM public.candidate_exam_sessions
    WHERE user_id = v_user_id AND exam_id = p_exam_id
    FOR UPDATE;

    IF FOUND THEN
        -- Case A: Session already submitted or terminated
        IF v_session.status IN ('submitted', 'terminated_lifecycle') THEN
            SELECT row_to_json(r.*)::jsonb INTO v_result
            FROM public.candidate_assessment_results r
            WHERE r.session_id = v_session.id;

            RETURN jsonb_build_object(
                'sessionId', v_session.id,
                'status', v_session.status,
                'isFinished', TRUE,
                'violationCount', v_session.violation_count,
                'submissionReason', v_session.submission_reason,
                'result', v_result
            );
        END IF;

        -- Case B: Session in progress but expired
        IF v_session.status = 'in_progress' AND v_now > v_session.expires_at THEN
            UPDATE public.candidate_exam_sessions
            SET status = 'expired',
                submitted_at = v_session.expires_at,
                submission_reason = 'Timer expired (Auto-submitted)',
                updated_at = v_now
            WHERE id = v_session.id
            RETURNING * INTO v_session;

            v_result := public._finalize_and_score_session(v_session, 'Timer expired (Auto-submitted)');

            RETURN jsonb_build_object(
                'sessionId', v_session.id,
                'status', 'expired',
                'isFinished', TRUE,
                'violationCount', v_session.violation_count,
                'submissionReason', 'Timer expired (Auto-submitted)',
                'result', v_result
            );
        END IF;

        -- Case C: Valid active session in progress (refresh recovery)
        v_remaining_seconds := GREATEST(0, EXTRACT(EPOCH FROM (v_session.expires_at - v_now))::integer);

        UPDATE public.candidate_exam_sessions
        SET last_heartbeat_at = v_now,
            updated_at = v_now
        WHERE id = v_session.id;

        RETURN jsonb_build_object(
            'sessionId', v_session.id,
            'status', 'in_progress',
            'isFinished', FALSE,
            'startedAt', v_session.started_at,
            'expiresAt', v_session.expires_at,
            'serverTime', v_now,
            'remainingSeconds', v_remaining_seconds,
            'violationCount', v_session.violation_count
        );
    END IF;

    -- Case D: Brand new session
    v_expires_at := v_now + (v_exam.duration_seconds || ' seconds')::interval;

    INSERT INTO public.candidate_exam_sessions (
        user_id,
        exam_id,
        student_name,
        register_number,
        examination_name,
        started_at,
        expires_at,
        status,
        violation_count,
        last_heartbeat_at,
        created_at,
        updated_at
    )
    VALUES (
        v_user_id,
        p_exam_id,
        p_student_name,
        p_register_number,
        p_examination_name,
        v_now,
        v_expires_at,
        'in_progress',
        0,
        v_now,
        v_now,
        v_now
    )
    RETURNING * INTO v_session;

    RETURN jsonb_build_object(
        'sessionId', v_session.id,
        'status', 'in_progress',
        'isFinished', FALSE,
        'startedAt', v_session.started_at,
        'expiresAt', v_session.expires_at,
        'serverTime', v_now,
        'remainingSeconds', v_exam.duration_seconds,
        'violationCount', 0
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Function: save_candidate_response
-- Upserts an MCQ answer with conflict resolution and server-authoritative expiry enforcement.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.save_candidate_response(
    p_session_id UUID,
    p_question_id TEXT,
    p_selected_option INTEGER,
    p_is_marked BOOLEAN DEFAULT FALSE,
    p_client_saved_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_session public.candidate_exam_sessions;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Lock session row to verify active status
    SELECT * INTO v_session
    FROM public.candidate_exam_sessions
    WHERE id = p_session_id AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Exam session not found or not owned by user';
    END IF;

    IF v_session.status <> 'in_progress' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Exam is no longer active (' || v_session.status || ')',
            'status', v_session.status
        );
    END IF;

    -- Verify time limit
    IF v_now > v_session.expires_at THEN
        -- Auto-expire session
        UPDATE public.candidate_exam_sessions
        SET status = 'expired',
            submitted_at = v_session.expires_at,
            submission_reason = 'Timer expired (Auto-submitted)',
            updated_at = v_now
        WHERE id = v_session.id
        RETURNING * INTO v_session;

        PERFORM public._finalize_and_score_session(v_session, 'Timer expired (Auto-submitted)');

        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Exam duration expired',
            'status', 'expired'
        );
    END IF;

    -- Upsert candidate response with timestamp comparison to resolve offline re-sync ordering
    INSERT INTO public.candidate_mcq_responses (
        session_id,
        question_id,
        selected_option_index,
        is_marked_for_review,
        client_saved_at,
        server_updated_at
    )
    VALUES (
        p_session_id,
        p_question_id,
        p_selected_option,
        p_is_marked,
        p_client_saved_at,
        v_now
    )
    ON CONFLICT (session_id, question_id) DO UPDATE SET
        selected_option_index = EXCLUDED.selected_option_index,
        is_marked_for_review = EXCLUDED.is_marked_for_review,
        client_saved_at = EXCLUDED.client_saved_at,
        server_updated_at = v_now
    WHERE EXCLUDED.client_saved_at >= candidate_mcq_responses.client_saved_at;

    UPDATE public.candidate_exam_sessions
    SET last_heartbeat_at = v_now,
        updated_at = v_now
    WHERE id = p_session_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'serverTime', v_now
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Function: save_candidate_coding_draft
-- Upserts a coding challenge solution with conflict resolution and expiry enforcement.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.save_candidate_coding_draft(
    p_session_id UUID,
    p_challenge_id TEXT,
    p_coding_draft TEXT,
    p_is_marked BOOLEAN DEFAULT FALSE,
    p_client_saved_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_session public.candidate_exam_sessions;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT * INTO v_session
    FROM public.candidate_exam_sessions
    WHERE id = p_session_id AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Exam session not found or not owned by user';
    END IF;

    IF v_session.status <> 'in_progress' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Exam is no longer active (' || v_session.status || ')',
            'status', v_session.status
        );
    END IF;

    IF v_now > v_session.expires_at THEN
        UPDATE public.candidate_exam_sessions
        SET status = 'expired',
            submitted_at = v_session.expires_at,
            submission_reason = 'Timer expired (Auto-submitted)',
            updated_at = v_now
        WHERE id = v_session.id
        RETURNING * INTO v_session;

        PERFORM public._finalize_and_score_session(v_session, 'Timer expired (Auto-submitted)');

        RETURN jsonb_build_object(
            'success', FALSE,
            'message', 'Exam duration expired',
            'status', 'expired'
        );
    END IF;

    INSERT INTO public.candidate_coding_drafts (
        session_id,
        challenge_id,
        coding_draft,
        is_marked_for_review,
        client_saved_at,
        server_updated_at
    )
    VALUES (
        p_session_id,
        p_challenge_id,
        p_coding_draft,
        p_is_marked,
        p_client_saved_at,
        v_now
    )
    ON CONFLICT (session_id, challenge_id) DO UPDATE SET
        coding_draft = EXCLUDED.coding_draft,
        is_marked_for_review = EXCLUDED.is_marked_for_review,
        client_saved_at = EXCLUDED.client_saved_at,
        server_updated_at = v_now
    WHERE EXCLUDED.client_saved_at >= candidate_coding_drafts.client_saved_at;

    UPDATE public.candidate_exam_sessions
    SET last_heartbeat_at = v_now,
        updated_at = v_now
    WHERE id = p_session_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'serverTime', v_now
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Function: record_lifecycle_violation
-- Handles browser focus/visibility interruptions with server-side deduplication.
-- Strike 1: Records violation and permits warning on return.
-- Strike 2: Atomically triggers immediate session termination and submission.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_lifecycle_violation(
    p_session_id UUID,
    p_signal_type TEXT,
    p_client_timestamp TIMESTAMPTZ DEFAULT NOW(),
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_session public.candidate_exam_sessions;
    v_now TIMESTAMPTZ := NOW();
    v_last_violation_time TIMESTAMPTZ;
    v_next_count INTEGER;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Lock session row to ensure serial processing of violations
    SELECT * INTO v_session
    FROM public.candidate_exam_sessions
    WHERE id = p_session_id AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session not found';
    END IF;

    -- If already finalized, discard further violations
    IF v_session.status <> 'in_progress' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'violationCount', v_session.violation_count,
            'isTerminated', TRUE,
            'status', v_session.status
        );
    END IF;

    -- Deduplication guard: ignore overlapping signals occurring within 400ms of last violation
    SELECT MAX(server_recorded_at) INTO v_last_violation_time
    FROM public.candidate_lifecycle_violations
    WHERE session_id = p_session_id;

    IF v_last_violation_time IS NOT NULL AND (v_now - v_last_violation_time) < INTERVAL '400 milliseconds' THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'deduplicated', TRUE,
            'violationCount', v_session.violation_count,
            'isTerminated', FALSE
        );
    END IF;

    v_next_count := v_session.violation_count + 1;

    -- Strike 1: Record and stage warning
    IF v_next_count = 1 THEN
        INSERT INTO public.candidate_lifecycle_violations (
            session_id,
            violation_number,
            signal_type,
            client_timestamp,
            server_recorded_at,
            metadata
        )
        VALUES (
            p_session_id,
            1,
            p_signal_type,
            p_client_timestamp,
            v_now,
            p_metadata
        );

        UPDATE public.candidate_exam_sessions
        SET violation_count = 1,
            last_heartbeat_at = v_now,
            updated_at = v_now
        WHERE id = p_session_id;

        RETURN jsonb_build_object(
            'success', TRUE,
            'violationCount', 1,
            'isTerminated', FALSE,
            'warningRequired', TRUE
        );
    END IF;

    -- Strike 2: Atomic Termination and Auto-Submission
    IF v_next_count >= 2 THEN
        INSERT INTO public.candidate_lifecycle_violations (
            session_id,
            violation_number,
            signal_type,
            client_timestamp,
            server_recorded_at,
            metadata
        )
        VALUES (
            p_session_id,
            2,
            p_signal_type,
            p_client_timestamp,
            v_now,
            p_metadata
        )
        ON CONFLICT (session_id, violation_number) DO NOTHING;

        UPDATE public.candidate_exam_sessions
        SET violation_count = 2,
            status = 'terminated_lifecycle',
            submitted_at = v_now,
            submission_reason = 'Second lifecycle violation (Integrity auto-submission)',
            last_heartbeat_at = v_now,
            updated_at = v_now
        WHERE id = p_session_id
        RETURNING * INTO v_session;

        v_result := public._finalize_and_score_session(v_session, 'Second lifecycle violation (Integrity auto-submission)');

        RETURN jsonb_build_object(
            'success', TRUE,
            'violationCount', 2,
            'isTerminated', TRUE,
            'reason', 'Second lifecycle violation (Integrity auto-submission)',
            'result', v_result
        );
    END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Function: submit_exam_session
-- Submits the exam, scores MCQs against secret keys, and prevents duplicate submissions.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_exam_session(
    p_session_id UUID,
    p_reason TEXT DEFAULT 'Manual submission by candidate'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_session public.candidate_exam_sessions;
    v_now TIMESTAMPTZ := NOW();
    v_final_reason TEXT;
    v_existing_result JSONB;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Row lock session to prevent race conditions on duplicate clicks
    SELECT * INTO v_session
    FROM public.candidate_exam_sessions
    WHERE id = p_session_id AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session not found';
    END IF;

    -- Guard against duplicate submission: return existing outcome idempotently
    IF v_session.status IN ('submitted', 'terminated_lifecycle', 'expired') THEN
        SELECT row_to_json(r.*)::jsonb INTO v_existing_result
        FROM public.candidate_assessment_results r
        WHERE r.session_id = p_session_id;

        RETURN jsonb_build_object(
            'success', TRUE,
            'alreadySubmitted', TRUE,
            'status', v_session.status,
            'submissionReason', v_session.submission_reason,
            'result', v_existing_result
        );
    END IF;

    -- Determine authoritative submission reason
    IF v_now > v_session.expires_at THEN
        v_final_reason := 'Timer expired (Auto-submitted)';
    ELSE
        v_final_reason := COALESCE(NULLIF(TRIM(p_reason), ''), 'Manual submission by candidate');
    END IF;

    UPDATE public.candidate_exam_sessions
    SET status = 'submitted',
        submitted_at = v_now,
        submission_reason = v_final_reason,
        updated_at = v_now
    WHERE id = p_session_id
    RETURNING * INTO v_session;

    -- Authoritative scoring
    v_result := public._finalize_and_score_session(v_session, v_final_reason);

    RETURN jsonb_build_object(
        'success', TRUE,
        'alreadySubmitted', FALSE,
        'status', 'submitted',
        'submissionReason', v_final_reason,
        'result', v_result
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- Security Hardening: Revoke execution from PUBLIC and grant only to authenticated candidates
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public._finalize_and_score_session(public.candidate_exam_sessions, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.start_or_resume_exam_session(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.save_candidate_response(UUID, TEXT, INTEGER, BOOLEAN, TIMESTAMPTZ) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.save_candidate_coding_draft(UUID, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.record_lifecycle_violation(UUID, TEXT, TIMESTAMPTZ, JSONB) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.submit_exam_session(UUID, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.start_or_resume_exam_session(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_candidate_response(UUID, TEXT, INTEGER, BOOLEAN, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_candidate_coding_draft(UUID, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_lifecycle_violation(UUID, TEXT, TIMESTAMPTZ, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_exam_session(UUID, TEXT) TO authenticated;
