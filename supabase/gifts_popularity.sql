-- Gifts (shop) + post gifting + recipient popularity points.
-- Run after wallets, coin_transactions, profiles, posts exist.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS popularity_points BIGINT NOT NULL DEFAULT 0 CHECK (popularity_points >= 0);

CREATE TABLE IF NOT EXISTS public.gift_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind TEXT NOT NULL CHECK (kind IN ('flower', 'rabbit', 'cat')),
  title TEXT NOT NULL,
  price_score INTEGER NOT NULL CHECK (price_score >= 0),
  popularity_points INTEGER NOT NULL CHECK (popularity_points >= 0),
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gift_items_active_sort
  ON public.gift_items (is_active, sort_order ASC, created_at DESC);

ALTER TABLE public.gift_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "gift_items_select" ON public.gift_items;
CREATE POLICY "gift_items_select" ON public.gift_items
  FOR SELECT TO authenticated
  USING (
    is_active = TRUE
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND COALESCE(p.is_admin, FALSE) = TRUE
    )
  );

DROP POLICY IF EXISTS "gift_items_admin_write" ON public.gift_items;
CREATE POLICY "gift_items_admin_write" ON public.gift_items
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND COALESCE(p.is_admin, FALSE) = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND COALESCE(p.is_admin, FALSE) = TRUE
    )
  );

CREATE TABLE IF NOT EXISTS public.post_gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(post_id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gift_item_id UUID NOT NULL REFERENCES public.gift_items(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_post_gifts_post ON public.post_gifts(post_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_gifts_sender ON public.post_gifts(sender_id, created_at DESC);

ALTER TABLE public.post_gifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_gifts_select_auth" ON public.post_gifts;
CREATE POLICY "post_gifts_select_auth" ON public.post_gifts
  FOR SELECT TO authenticated
  USING (TRUE);

DROP POLICY IF EXISTS "post_gifts_no_insert" ON public.post_gifts;
CREATE POLICY "post_gifts_no_insert" ON public.post_gifts
  FOR INSERT TO authenticated
  WITH CHECK (FALSE);

-- Default catalog (idempotent)
INSERT INTO public.gift_items (kind, title, price_score, popularity_points, sort_order, is_active)
SELECT * FROM (VALUES
  ('flower'::TEXT, 'ပန်းပွင့်', 100, 5, 0, TRUE),
  ('rabbit'::TEXT, 'ယုန်', 200, 12, 1, TRUE),
  ('cat'::TEXT, 'ကြောင်', 150, 8, 2, TRUE)
) AS v(kind, title, price_score, popularity_points, sort_order, is_active)
WHERE NOT EXISTS (SELECT 1 FROM public.gift_items LIMIT 1);

CREATE OR REPLACE FUNCTION public.send_post_gift(p_post_id UUID, p_gift_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_author UUID;
  v_price INTEGER;
  v_pop INTEGER;
  v_active BOOLEAN;
  v_before INTEGER;
  v_after INTEGER;
  v_rec_pop BIGINT;
  v_row_id UUID;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'not_authenticated');
  END IF;

  SELECT p.user_id INTO v_author
  FROM public.posts p
  WHERE p.post_id = p_post_id
    AND COALESCE(p.is_deleted, FALSE) = FALSE
    AND COALESCE(p.moderation_status, 'approved') = 'approved';

  IF v_author IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'post_not_found');
  END IF;

  IF v_author = v_uid THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'cannot_gift_own_post');
  END IF;

  SELECT g.price_score, g.popularity_points, g.is_active
  INTO v_price, v_pop, v_active
  FROM public.gift_items g
  WHERE g.id = p_gift_item_id;

  IF NOT FOUND OR v_active IS NOT TRUE THEN
    RETURN jsonb_build_object('ok', FALSE, 'error', 'gift_not_found');
  END IF;

  INSERT INTO public.wallets (user_id, balance, updated_at)
  VALUES (v_uid, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT w.balance INTO v_before
  FROM public.wallets w
  WHERE w.user_id = v_uid
  FOR UPDATE;

  IF v_before IS NULL THEN
    v_before := 0;
  END IF;

  IF v_before < v_price THEN
    RETURN jsonb_build_object(
      'ok', FALSE,
      'error', 'insufficient_balance',
      'balance', v_before,
      'required', v_price
    );
  END IF;

  v_after := v_before - v_price;

  UPDATE public.wallets
  SET balance = v_after, updated_at = NOW()
  WHERE user_id = v_uid;

  INSERT INTO public.coin_transactions (
    user_id, delta, balance_after, source_type, source_id, note, created_by, created_at
  ) VALUES (
    v_uid,
    -v_price,
    v_after,
    'system',
    p_post_id,
    'post_gift_send',
    v_uid,
    NOW()
  );

  UPDATE public.profiles
  SET popularity_points = COALESCE(popularity_points, 0) + v_pop
  WHERE id = v_author
  RETURNING popularity_points INTO v_rec_pop;

  INSERT INTO public.post_gifts (post_id, sender_id, gift_item_id)
  VALUES (p_post_id, v_uid, p_gift_item_id)
  RETURNING id INTO v_row_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'new_balance', v_after,
    'recipient_popularity', v_rec_pop,
    'post_gift_id', v_row_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public.send_post_gift(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_post_gift(UUID, UUID) TO authenticated;

COMMENT ON COLUMN public.profiles.popularity_points IS
  'Popularity from gifts received on posts; shown on profile.';
