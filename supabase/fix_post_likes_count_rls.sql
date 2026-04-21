-- Fix: likes_count stays wrong when someone other than the post author likes.
-- Cause: trigger runs as the liker; RLS on `posts` only allows the post owner to UPDATE.
-- Run in Supabase SQL Editor (once per project).

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET likes_count = likes_count + 1 WHERE post_id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE post_id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Realign like totals with post_likes (fixes rows already out of sync)
UPDATE posts p
SET likes_count = (SELECT COUNT(*)::int FROM post_likes l WHERE l.post_id = p.post_id);
