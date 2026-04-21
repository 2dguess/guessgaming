-- Popular digits: 0–99 rows per window (user_count starts at 0), +1 per non-admin bet.
-- get_popular_digits ensures rows exist; top 10 = highest user_count (> 0).
-- Run once on Supabase.

CREATE OR REPLACE FUNCTION public.popular_digit_ensure_counts_for_window (p_wk TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.popular_digit_counts (window_key, digit, user_count, updated_at)
  SELECT p_wk, g::SMALLINT, 0, NOW()
  FROM generate_series(0, 99) AS g
  ON CONFLICT (window_key, digit) DO NOTHING;
END;
$$;

ALTER FUNCTION public.popular_digit_ensure_counts_for_window (TEXT)
  SET row_security = off;

CREATE OR REPLACE FUNCTION public.popular_digit_record_first_pick (
  p_user_id UUID,
  p_digit INT,
  p_at TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  wk TEXT;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_user_id AND COALESCE(p.is_admin, FALSE)
  ) THEN
    RETURN;
  END IF;

  IF p_digit < 0 OR p_digit > 99 THEN
    RETURN;
  END IF;

  wk := public.popular_digit_window_key(p_at);
  IF wk IS NULL THEN
    RETURN;
  END IF;

  PERFORM public.popular_digit_ensure_counts_for_window(wk);

  UPDATE public.popular_digit_counts
  SET
    user_count = user_count + 1,
    updated_at = NOW()
  WHERE window_key = wk
    AND digit = p_digit::SMALLINT;
END;
$$;

ALTER FUNCTION public.popular_digit_record_first_pick (UUID, INT, TIMESTAMPTZ)
  SET row_security = off;

CREATE OR REPLACE FUNCTION public.trg_bets_popular_digit ()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  BEGIN
    PERFORM public.popular_digit_record_first_pick(NEW.user_id, NEW.digit::INT, NEW.created_at);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'popular_digit_record_first_pick failed (bet still saved): %', SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS bets_after_insert_popular ON public.bets;
CREATE TRIGGER bets_after_insert_popular
  AFTER INSERT ON public.bets
  FOR EACH ROW
  EXECUTE PROCEDURE public.trg_bets_popular_digit ();

CREATE OR REPLACE FUNCTION public.get_popular_digits (p_digest TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  wk TEXT;
  v_digest TEXT;
  v_rows JSONB;
  v_sig TEXT;
BEGIN
  wk := public.popular_digit_window_key(NOW());

  IF wk IS NULL THEN
    IF p_digest IS NOT NULL AND p_digest = 'closed' THEN
      RETURN jsonb_build_object(
        'unchanged', TRUE,
        'session_active', FALSE,
        'window_key', NULL,
        'digest', 'closed',
        'digits', '[]'::JSONB
      );
    END IF;
    RETURN jsonb_build_object(
      'unchanged', FALSE,
      'session_active', FALSE,
      'window_key', NULL,
      'digest', 'closed',
      'digits', '[]'::JSONB
    );
  END IF;

  PERFORM public.popular_digit_ensure_counts_for_window(wk);

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object('digit', s.digit, 'people_count', s.user_count)
      ORDER BY s.user_count DESC, s.digit ASC
    ),
    '[]'::JSONB
  )
  INTO v_rows
  FROM (
    SELECT c.digit, c.user_count
    FROM public.popular_digit_counts c
    WHERE c.window_key = wk
      AND c.user_count > 0
    ORDER BY c.user_count DESC, c.digit ASC
    LIMIT 10
  ) s;

  SELECT COALESCE(
    string_agg(x.digit::TEXT || ':' || x.user_count::TEXT, '|' ORDER BY x.user_count DESC, x.digit ASC),
    ''
  )
  INTO v_sig
  FROM (
    SELECT c.digit, c.user_count
    FROM public.popular_digit_counts c
    WHERE c.window_key = wk
      AND c.user_count > 0
    ORDER BY c.user_count DESC, c.digit ASC
    LIMIT 10
  ) x;

  v_digest := md5(wk || ':' || v_sig);

  IF p_digest IS NOT NULL AND p_digest = v_digest THEN
    RETURN jsonb_build_object(
      'unchanged', TRUE,
      'session_active', TRUE,
      'window_key', wk,
      'digest', v_digest,
      'digits', v_rows
    );
  END IF;

  RETURN jsonb_build_object(
    'unchanged', FALSE,
    'session_active', TRUE,
    'window_key', wk,
    'digest', v_digest,
    'digits', v_rows
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_trending_digits ()
RETURNS TABLE(digit INT, people_count BIGINT)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    (e->>'digit')::INT,
    (e->>'people_count')::BIGINT
  FROM jsonb_array_elements(
    COALESCE(public.get_popular_digits(NULL)->'digits', '[]'::JSONB)
  ) AS e;
$$;

GRANT EXECUTE ON FUNCTION public.get_popular_digits (TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_popular_digits (TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_trending_digits () TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_trending_digits () TO anon;
