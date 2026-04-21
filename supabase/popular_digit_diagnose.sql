-- Run in Supabase SQL Editor when popular_digit_counts stays empty after picks.
-- 1) Trigger on public.bets (must exist for aggregation to run)
SELECT tgname AS trigger_name, tgenabled AS enabled
FROM pg_trigger
WHERE tgrelid = 'public.bets'::regclass
  AND NOT tgisinternal
ORDER BY tgname;

-- 2) Rows for today's window (window_key: YYYY-MM-DD_am | YYYY-MM-DD_pm)
--    After ensure + picks: 100 rows per window (digits 0–99); user_count = pick volume.
SELECT COUNT(*) AS count_rows_total
FROM public.popular_digit_counts
WHERE window_key = (SELECT public.popular_digit_window_key(NOW()));

SELECT COUNT(*) AS count_rows_positive
FROM public.popular_digit_counts
WHERE window_key = (SELECT public.popular_digit_window_key(NOW()))
  AND user_count > 0;

-- 3) If trigger missing, re-apply from popular_digits_sessions.sql:
--    - CREATE TRIGGER bets_after_insert_popular ...
--    And ensure fix_popular_digit_on_conflict_alias.sql was applied for the function body.
