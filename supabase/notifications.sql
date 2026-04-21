-- In-app notifications. Run in Supabase SQL Editor.
-- Recipients only read/update their rows; inserts happen via SECURITY DEFINER triggers.

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('post_like', 'comment', 'reply', 'follow')),
  post_id UUID REFERENCES posts(post_id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(comment_id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id, created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Recipients read own notifications" ON notifications;
CREATE POLICY "Recipients read own notifications"
  ON notifications FOR SELECT USING (auth.uid() = recipient_id);

DROP POLICY IF EXISTS "Recipients mark notifications read" ON notifications;
CREATE POLICY "Recipients mark notifications read"
  ON notifications FOR UPDATE USING (auth.uid() = recipient_id);

-- No INSERT/DELETE for authenticated users (only triggers below).

CREATE OR REPLACE FUNCTION notify_post_liked()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM posts WHERE post_id = NEW.post_id;
  IF owner_id IS NOT NULL AND owner_id <> NEW.user_id THEN
    INSERT INTO notifications (recipient_id, actor_id, type, post_id)
    VALUES (owner_id, NEW.user_id, 'post_like', NEW.post_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_post_liked ON post_likes;
CREATE TRIGGER trg_notify_post_liked
  AFTER INSERT ON post_likes
  FOR EACH ROW EXECUTE FUNCTION notify_post_liked();

CREATE OR REPLACE FUNCTION notify_new_comment()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  owner_id UUID;
  parent_author UUID;
BEGIN
  SELECT user_id INTO owner_id FROM posts WHERE post_id = NEW.post_id;

  IF NEW.parent_comment_id IS NULL THEN
    IF owner_id IS NOT NULL AND owner_id <> NEW.user_id THEN
      INSERT INTO notifications (recipient_id, actor_id, type, post_id, comment_id)
      VALUES (owner_id, NEW.user_id, 'comment', NEW.post_id, NEW.comment_id);
    END IF;
  ELSE
    SELECT user_id INTO parent_author FROM comments WHERE comment_id = NEW.parent_comment_id;
    IF parent_author IS NOT NULL AND parent_author <> NEW.user_id THEN
      INSERT INTO notifications (recipient_id, actor_id, type, post_id, comment_id)
      VALUES (parent_author, NEW.user_id, 'reply', NEW.post_id, NEW.comment_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_comment ON comments;
CREATE TRIGGER trg_notify_comment
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION notify_new_comment();

CREATE OR REPLACE FUNCTION notify_new_follow()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO notifications (recipient_id, actor_id, type)
  VALUES (NEW.following_id, NEW.follower_id, 'follow');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_follow ON follows;
CREATE TRIGGER trg_notify_follow
  AFTER INSERT ON follows
  FOR EACH ROW EXECUTE FUNCTION notify_new_follow();

-- ---------------------------------------------------------------------------
-- Realtime (for Flutter app live refresh)
-- In Supabase Dashboard: Database → Replication → enable `notifications` for
-- supabase_realtime, OR run once (skip if already added):
--
--   ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
-- ---------------------------------------------------------------------------
