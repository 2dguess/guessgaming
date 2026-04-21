-- Phase 1 feed optimization: replace N+1 client reads with one RPC page query.
-- Run in Supabase SQL editor.

-- Cursor-friendly feed index.
CREATE INDEX IF NOT EXISTS idx_posts_created_post_cursor
ON posts(created_at DESC, post_id DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user_created_post_cursor
ON posts(user_id, created_at DESC, post_id DESC);

-- Fast top-level comment counting (parent_comment_id IS NULL).
CREATE INDEX IF NOT EXISTS idx_comments_top_level_by_post
ON comments(post_id)
WHERE parent_comment_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_follows_follower_following
ON follows(follower_id, following_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_post
ON post_likes(user_id, post_id);

-- Feed page RPC (single query): posts + profiles + liked_by_me + top-level comments.
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
      -- Guard: caller can only request own personalized view.
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
      'created_at', pr.created_at
    ) AS profiles
  FROM filtered_posts fp
  JOIN profiles pr ON pr.id = fp.user_id
  LEFT JOIN top_level_counts tc ON tc.post_id = fp.post_id
  LEFT JOIN my_likes ml ON ml.post_id = fp.post_id
  ORDER BY fp.created_at DESC, fp.post_id DESC;
$$;

GRANT EXECUTE ON FUNCTION get_feed_posts_page(UUID, TEXT, INT, TIMESTAMPTZ, UUID) TO authenticated;

