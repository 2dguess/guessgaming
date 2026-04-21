-- Align Play leaderboards + badge ranks with app header score and real win payouts.
-- Run in Supabase SQL editor (replaces functions from leaderboard_profile_badges.sql + leaderboard_badges_batch.sql).
--
-- 1) Top score: COALESCE(available_balance, balance) — matches betting header (available first).
-- 2) Best match: MAX((amount * 80)::bigint) for status = 'win' — virtual score from one pick (all time).

CREATE OR REPLACE FUNCTION public.get_play_leaderboards(p_limit INT DEFAULT 10)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_score JSONB;
  v_match JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(obj ORDER BY ord), '[]'::JSONB)
  INTO v_score
  FROM (
    SELECT
      jsonb_build_object(
        'rank', s.rnk,
        'user_id', s.user_id,
        'username', s.username,
        'avatar_url', s.avatar_url,
        'value', s.val
      ) AS obj,
      s.rnk AS ord
    FROM (
      SELECT
        ROW_NUMBER() OVER (
          ORDER BY COALESCE(w.available_balance, w.balance, 0) DESC NULLS LAST
        ) AS rnk,
        p.id AS user_id,
        p.username,
        p.avatar_url,
        COALESCE(w.available_balance, w.balance, 0)::BIGINT AS val
      FROM public.profiles p
      LEFT JOIN public.wallets w ON w.user_id = p.id
      WHERE COALESCE(p.is_admin, FALSE) = FALSE
    ) s
    WHERE s.rnk <= p_limit
  ) sub;

  SELECT COALESCE(jsonb_agg(obj ORDER BY ord), '[]'::JSONB)
  INTO v_match
  FROM (
    SELECT
      jsonb_build_object(
        'rank', s.rnk,
        'user_id', s.user_id,
        'username', s.username,
        'avatar_url', s.avatar_url,
        'value', s.val
      ) AS obj,
      s.rnk AS ord
    FROM (
      SELECT
        ROW_NUMBER() OVER (ORDER BY m.best_match DESC) AS rnk,
        p.id AS user_id,
        p.username,
        p.avatar_url,
        m.best_match AS val
      FROM public.profiles p
      INNER JOIN (
        SELECT
          user_id,
          MAX((amount * 80)::BIGINT) AS best_match
        FROM public.bets
        WHERE status = 'win'
        GROUP BY user_id
      ) m ON m.user_id = p.id
      WHERE COALESCE(p.is_admin, FALSE) = FALSE
    ) s
    WHERE s.rnk <= p_limit
  ) sub;

  RETURN jsonb_build_object(
    'by_score', v_score,
    'by_best_match', v_match
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_play_leaderboards(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_play_leaderboards(INT) TO anon;

CREATE OR REPLACE FUNCTION public.get_profile_leaderboard_badges(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_score_rnk INT;
  v_match_rnk INT;
BEGIN
  SELECT COALESCE(is_admin, FALSE) INTO v_is_admin
  FROM public.profiles WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'score_rank', NULL,
      'match_rank', NULL,
      'score_top10', FALSE,
      'match_top10', FALSE
    );
  END IF;

  IF v_is_admin THEN
    RETURN jsonb_build_object(
      'score_rank', NULL,
      'match_rank', NULL,
      'score_top10', FALSE,
      'match_top10', FALSE
    );
  END IF;

  SELECT s.rnk INTO v_score_rnk
  FROM (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (
        ORDER BY COALESCE(w.available_balance, w.balance, 0) DESC NULLS LAST
      ) AS rnk
    FROM public.profiles p
    LEFT JOIN public.wallets w ON w.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ) s
  WHERE s.uid = p_user_id;

  SELECT x.rnk INTO v_match_rnk
  FROM (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (ORDER BY COALESCE(m.best_match, 0) DESC) AS rnk
    FROM public.profiles p
    LEFT JOIN (
      SELECT
        user_id,
        MAX((amount * 80)::BIGINT) AS best_match
      FROM public.bets
      WHERE status = 'win'
      GROUP BY user_id
    ) m ON m.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ) x
  WHERE x.uid = p_user_id;

  RETURN jsonb_build_object(
    'score_rank', v_score_rnk,
    'match_rank', v_match_rnk,
    'score_top10', COALESCE(v_score_rnk, 999) <= 10,
    'match_top10', COALESCE(v_match_rnk, 999) <= 10
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_leaderboard_badges(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profile_leaderboard_badges(UUID) TO anon;

CREATE OR REPLACE FUNCTION public.get_leaderboard_badges_for_users(p_user_ids UUID[])
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH score_ranks AS (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (
        ORDER BY COALESCE(w.available_balance, w.balance, 0) DESC NULLS LAST
      ) AS rnk
    FROM public.profiles p
    LEFT JOIN public.wallets w ON w.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ),
  match_ranks AS (
    SELECT
      p.id AS uid,
      ROW_NUMBER() OVER (ORDER BY COALESCE(m.best_match, 0) DESC) AS rnk
    FROM public.profiles p
    LEFT JOIN (
      SELECT
        user_id,
        MAX((amount * 80)::BIGINT) AS best_match
      FROM public.bets
      WHERE status = 'win'
      GROUP BY user_id
    ) m ON m.user_id = p.id
    WHERE COALESCE(p.is_admin, FALSE) = FALSE
  ),
  input AS (
    SELECT DISTINCT u AS uid
    FROM unnest(COALESCE(p_user_ids, ARRAY[]::UUID[])) AS u
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'user_id', i.uid,
        'score_rank', CASE WHEN COALESCE(p.is_admin, FALSE) THEN NULL ELSE sr.rnk END,
        'match_rank', CASE WHEN COALESCE(p.is_admin, FALSE) THEN NULL ELSE mr.rnk END,
        'score_top10', CASE WHEN COALESCE(p.is_admin, FALSE) THEN FALSE ELSE COALESCE(sr.rnk, 999) <= 10 END,
        'match_top10', CASE WHEN COALESCE(p.is_admin, FALSE) THEN FALSE ELSE COALESCE(mr.rnk, 999) <= 10 END
      )
      ORDER BY i.uid
    ),
    '[]'::jsonb
  )
  FROM input i
  JOIN public.profiles p ON p.id = i.uid
  LEFT JOIN score_ranks sr ON sr.uid = i.uid
  LEFT JOIN match_ranks mr ON mr.uid = i.uid;
$$;

GRANT EXECUTE ON FUNCTION public.get_leaderboard_badges_for_users(UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard_badges_for_users(UUID[]) TO anon;
