-- Reactions (likes) on DM messages. Run in Supabase SQL Editor after dm_chat.sql.

CREATE TABLE IF NOT EXISTS public.dm_message_likes (
  message_id UUID NOT NULL REFERENCES public.dm_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_dm_message_likes_message
  ON public.dm_message_likes(message_id);

ALTER TABLE public.dm_message_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dm_message_likes_select_member" ON public.dm_message_likes;
CREATE POLICY "dm_message_likes_select_member" ON public.dm_message_likes
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.dm_messages m
      JOIN public.dm_threads t ON t.id = m.thread_id
      WHERE m.id = dm_message_likes.message_id
        AND (auth.uid() = t.user_a OR auth.uid() = t.user_b)
    )
  );

DROP POLICY IF EXISTS "dm_message_likes_insert_member" ON public.dm_message_likes;
CREATE POLICY "dm_message_likes_insert_member" ON public.dm_message_likes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.dm_messages m
      JOIN public.dm_threads t ON t.id = m.thread_id
      WHERE m.id = dm_message_likes.message_id
        AND (auth.uid() = t.user_a OR auth.uid() = t.user_b)
    )
  );

DROP POLICY IF EXISTS "dm_message_likes_delete_own" ON public.dm_message_likes;
CREATE POLICY "dm_message_likes_delete_own" ON public.dm_message_likes
  FOR DELETE USING (auth.uid() = user_id);
