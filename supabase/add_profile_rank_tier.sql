-- Rank tier badge (1 = highest … 10 = starter) shown next to usernames in the app.
-- Run in Supabase SQL Editor after backup.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS rank_tier SMALLINT
  NULL
  CHECK (rank_tier IS NULL OR (rank_tier >= 1 AND rank_tier <= 10));

COMMENT ON COLUMN public.profiles.rank_tier IS
  'Optional display tier for rank badge: 1 Godly … 10 Wood. NULL = hide badge.';

-- Feed RPC: include rank_tier in embedded profiles JSON (must match Flutter AppProfile.fromJson).
CREATE OR REPLACE FUNCTION get_feed_posts_page(
  p_user_id UUID DEFAULT NULL,
  p_mode TEXT DEFAULT 'home',
  p_limit INT DEFAULT 20,
  p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
  p_cursor_post_id UUID DEFAULT NULL
)
RETURNS TABLE (
  post_id UUID,
  user_id UUID,
  content TEXT,
  image_url TEXT,
  likes_count INT,
  comments_count INT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  liked_by_me BOOLEAN,
  profiles JSONB
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  WITH filtered_posts AS (
    SELECT
      p.post_id,
      p.user_id,
      p.content,
      p.image_url,
      p.likes_count,
      p.created_at,
      p.updated_at
    FROM posts p
    WHERE
      (p_user_id IS NULL OR p_user_id = auth.uid())
      AND COALESCE(p.is_deleted, FALSE) = FALSE
      AND COALESCE(p.moderation_status, 'approved') = 'approved'
      AND p_mode IN ('home', 'trend')
      AND
      (
        p_mode = 'trend'
        OR (
          p_mode = 'home'
          AND p_user_id IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM follows f
            WHERE f.follower_id = p_user_id
              AND f.following_id = p.user_id
          )
        )
      )
      AND (
        p_mode != 'trend'
        OR p.created_at >= (NOW() - INTERVAL '24 hours')
      )
      AND (
        p_cursor_created_at IS NULL
        OR (p.created_at, p.post_id) < (p_cursor_created_at, p_cursor_post_id)
      )
    ORDER BY p.created_at DESC, p.post_id DESC
    LIMIT GREATEST(1, LEAST(p_limit, 100))
  ),
  top_level_counts AS (
    SELECT c.post_id, COUNT(*)::INT AS top_level_count
    FROM comments c
    JOIN filtered_posts fp ON fp.post_id = c.post_id
    WHERE c.parent_comment_id IS NULL
    GROUP BY c.post_id
  ),
  my_likes AS (
    SELECT pl.post_id
    FROM post_likes pl
    JOIN filtered_posts fp ON fp.post_id = pl.post_id
    WHERE p_user_id IS NOT NULL
      AND pl.user_id = p_user_id
  )
  SELECT
    fp.post_id,
    fp.user_id,
    fp.content,
    fp.image_url,
    fp.likes_count,
    COALESCE(tc.top_level_count, 0)::INT AS comments_count,
    fp.created_at,
    fp.updated_at,
    (ml.post_id IS NOT NULL) AS liked_by_me,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url,
      'created_at', pr.created_at,
      'rank_tier', pr.rank_tier
    ) AS profiles
  FROM filtered_posts fp
  JOIN profiles pr ON pr.id = fp.user_id
  LEFT JOIN top_level_counts tc ON tc.post_id = fp.post_id
  LEFT JOIN my_likes ml ON ml.post_id = fp.post_id
  ORDER BY fp.created_at DESC, fp.post_id DESC;
$$;

-- Comments RPC: include rank_tier in embedded profiles JSON.
CREATE OR REPLACE FUNCTION get_post_comments(
  p_post_id UUID,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  comment_id UUID,
  post_id UUID,
  user_id UUID,
  parent_comment_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  likes_count INT,
  liked_by_me BOOLEAN,
  profiles JSONB
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  WITH base AS (
    SELECT
      c.comment_id,
      c.post_id,
      c.user_id,
      c.parent_comment_id,
      c.content,
      c.created_at,
      COALESCE(c.likes_count, 0)::INT AS likes_count
    FROM comments c
    WHERE c.post_id = p_post_id
      AND (p_user_id IS NULL OR p_user_id = auth.uid())
    ORDER BY c.created_at ASC
  ),
  my_likes AS (
    SELECT cl.comment_id
    FROM comment_likes cl
    JOIN base b ON b.comment_id = cl.comment_id
    WHERE p_user_id IS NOT NULL
      AND cl.user_id = p_user_id
  )
  SELECT
    b.comment_id,
    b.post_id,
    b.user_id,
    b.parent_comment_id,
    b.content,
    b.created_at,
    b.likes_count,
    (ml.comment_id IS NOT NULL) AS liked_by_me,
    jsonb_build_object(
      'id', p.id,
      'username', p.username,
      'avatar_url', p.avatar_url,
      'created_at', p.created_at,
      'rank_tier', p.rank_tier
    ) AS profiles
  FROM base b
  JOIN profiles p ON p.id = b.user_id
  LEFT JOIN my_likes ml ON ml.comment_id = b.comment_id
  ORDER BY b.created_at ASC;
$$;
