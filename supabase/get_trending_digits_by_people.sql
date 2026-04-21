-- Run on Supabase SQL editor if your DB still has the old get_trending_digits().
-- Top 10 digits ranked by distinct users who picked that digit (last 7 days).
-- Same user picking the same digit multiple times counts as 1.
--
-- Must DROP first: Postgres does not allow CREATE OR REPLACE when OUT/return columns change
-- (e.g. bet_count -> people_count).

DROP FUNCTION IF EXISTS public.get_trending_digits();

CREATE OR REPLACE FUNCTION public.get_trending_digits()
RETURNS TABLE(digit INTEGER, people_count BIGINT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.digit,
    COUNT(DISTINCT b.user_id)::BIGINT AS people_count
  FROM public.bets b
  INNER JOIN public.profiles p ON p.id = b.user_id
    AND COALESCE(p.is_admin, FALSE) = FALSE
  WHERE b.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days'
  GROUP BY b.digit
  ORDER BY COUNT(DISTINCT b.user_id) DESC, b.digit ASC
  LIMIT 10;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trending_digits() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_trending_digits() TO anon;
