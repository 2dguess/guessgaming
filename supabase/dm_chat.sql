-- Direct messages (1:1). Run in Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS dm_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_b UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT dm_pair_ordered CHECK (user_a < user_b),
  CONSTRAINT dm_not_self CHECK (user_a <> user_b),
  UNIQUE (user_a, user_b)
);

CREATE INDEX IF NOT EXISTS idx_dm_threads_user_a ON dm_threads(user_a);
CREATE INDEX IF NOT EXISTS idx_dm_threads_user_b ON dm_threads(user_b);
CREATE INDEX IF NOT EXISTS idx_dm_threads_last_at ON dm_threads(last_message_at DESC NULLS LAST);

CREATE TABLE IF NOT EXISTS dm_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES dm_threads(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT dm_body_not_empty CHECK (char_length(trim(body)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_dm_messages_thread_time ON dm_messages(thread_id, created_at DESC);

CREATE OR REPLACE FUNCTION dm_touch_thread_last_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE dm_threads SET last_message_at = NEW.created_at WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dm_messages_touch_thread ON dm_messages;
CREATE TRIGGER trg_dm_messages_touch_thread
  AFTER INSERT ON dm_messages
  FOR EACH ROW EXECUTE PROCEDURE dm_touch_thread_last_at();

ALTER TABLE dm_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dm_threads_select_member" ON dm_threads;
CREATE POLICY "dm_threads_select_member" ON dm_threads
  FOR SELECT USING (auth.uid() = user_a OR auth.uid() = user_b);

DROP POLICY IF EXISTS "dm_threads_insert_member" ON dm_threads;
CREATE POLICY "dm_threads_insert_member" ON dm_threads
  FOR INSERT WITH CHECK (
    auth.uid() IN (user_a, user_b)
  );

DROP POLICY IF EXISTS "dm_messages_select_member" ON dm_messages;
CREATE POLICY "dm_messages_select_member" ON dm_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM dm_threads t
      WHERE t.id = dm_messages.thread_id
        AND (auth.uid() = t.user_a OR auth.uid() = t.user_b)
    )
  );

DROP POLICY IF EXISTS "dm_messages_insert_self" ON dm_messages;
CREATE POLICY "dm_messages_insert_self" ON dm_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM dm_threads t
      WHERE t.id = dm_messages.thread_id
        AND (auth.uid() = t.user_a OR auth.uid() = t.user_b)
    )
  );
