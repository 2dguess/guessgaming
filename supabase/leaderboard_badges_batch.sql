-- Batch variant of get_profile_leaderboard_badges for feed/comments (one RPC per screen).
-- Run after leaderboard_profile_badges.sql

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
