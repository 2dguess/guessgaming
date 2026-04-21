-- Phase 1 comments optimization: load post comments in one RPC call.
-- Run in Supabase SQL editor.

CREATE INDEX IF NOT EXISTS idx_comments_post_created
ON comments(post_id, created_at ASC);

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
      'created_at', p.created_at
    ) AS profiles
  FROM base b
  JOIN profiles p ON p.id = b.user_id
  LEFT JOIN my_likes ml ON ml.comment_id = b.comment_id
  ORDER BY b.created_at ASC;
$$;

GRANT EXECUTE ON FUNCTION get_post_comments(UUID, UUID) TO anon, authenticated;
REVOKE EXECUTE ON FUNCTION get_post_comments(UUID, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION get_post_comments(UUID, UUID) TO authenticated;

