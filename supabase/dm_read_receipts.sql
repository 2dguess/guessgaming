-- Read receipts + unread conversation count for DM. Run in Supabase SQL Editor after dm_chat.sql.

ALTER TABLE dm_threads
  ADD COLUMN IF NOT EXISTS user_a_last_read_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS user_b_last_read_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION dm_mark_thread_read(p_thread_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  ua uuid;
  ub uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT user_a, user_b INTO ua, ub
  FROM dm_threads
  WHERE id = p_thread_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found';
  END IF;

  IF uid = ua THEN
    UPDATE dm_threads SET user_a_last_read_at = NOW() WHERE id = p_thread_id;
  ELSIF uid = ub THEN
    UPDATE dm_threads SET user_b_last_read_at = NOW() WHERE id = p_thread_id;
  ELSE
    RAISE EXCEPTION 'not a member';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION dm_mark_thread_read(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION dm_unread_conversation_count()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::integer
  FROM dm_threads t
  WHERE (t.user_a = auth.uid() OR t.user_b = auth.uid())
    AND EXISTS (
      SELECT 1
      FROM dm_messages m
      WHERE m.thread_id = t.id
        AND m.sender_id <> auth.uid()
        AND (
          (t.user_a = auth.uid() AND (t.user_a_last_read_at IS NULL OR m.created_at > t.user_a_last_read_at))
          OR
          (t.user_b = auth.uid() AND (t.user_b_last_read_at IS NULL OR m.created_at > t.user_b_last_read_at))
        )
    );
$$;

GRANT EXECUTE ON FUNCTION dm_unread_conversation_count() TO authenticated;

-- Per-thread count of inbound messages not yet read (for chat list badge: 2, 3, …)
CREATE OR REPLACE FUNCTION dm_unread_inbound_counts()
RETURNS TABLE(thread_id uuid, unread_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT m.thread_id, COUNT(*)::bigint
  FROM dm_messages m
  INNER JOIN dm_threads t ON t.id = m.thread_id
  WHERE (t.user_a = auth.uid() OR t.user_b = auth.uid())
    AND m.sender_id <> auth.uid()
    AND (
      (t.user_a = auth.uid() AND (t.user_a_last_read_at IS NULL OR m.created_at > t.user_a_last_read_at))
      OR
      (t.user_b = auth.uid() AND (t.user_b_last_read_at IS NULL OR m.created_at > t.user_b_last_read_at))
    )
  GROUP BY m.thread_id;
$$;

GRANT EXECUTE ON FUNCTION dm_unread_inbound_counts() TO authenticated;

-- Optional live badge / Seen refresh (Dashboard → Replication or SQL):
--   ALTER PUBLICATION supabase_realtime ADD TABLE dm_messages;
--   ALTER PUBLICATION supabase_realtime ADD TABLE dm_threads;
