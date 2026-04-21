-- Ensure Daily Free Coin mission is always present as 15,000 score/day.
-- Run in Supabase SQL Editor.

-- 1) Keep only one canonical daily_free_coin mission (old duplicates disabled).
WITH ranked AS (
  SELECT
    mission_id,
    ROW_NUMBER() OVER (
      ORDER BY
        CASE WHEN is_active THEN 0 ELSE 1 END,
        created_at DESC
    ) AS rn
  FROM public.missions
  WHERE mission_type = 'daily_free_coin'
)
UPDATE public.missions m
SET is_active = FALSE
FROM ranked r
WHERE m.mission_id = r.mission_id
  AND r.rn > 1;

-- 2) Upsert canonical mission row.
DO $$
DECLARE
  v_existing UUID;
BEGIN
  SELECT mission_id INTO v_existing
  FROM public.missions
  WHERE mission_type = 'daily_free_coin'
  ORDER BY is_active DESC, created_at DESC
  LIMIT 1;

  IF v_existing IS NULL THEN
    INSERT INTO public.missions (
      title,
      description,
      reward_amount,
      reward_coin,
      frequency,
      mission_type,
      mission_kind,
      mission_action,
      is_active,
      created_at
    )
    VALUES (
      'Daily Free Coin',
      'Claim 15,000 free score once per day. Auto reset at Myanmar midnight.',
      15000,
      15000,
      'daily',
      'daily_free_coin',
      'custom',
      'custom',
      TRUE,
      NOW()
    );
  ELSE
    UPDATE public.missions
    SET
      title = 'Daily Free Coin',
      description = 'Claim 15,000 free score once per day. Auto reset at Myanmar midnight.',
      reward_amount = 15000,
      reward_coin = 15000,
      frequency = 'daily',
      mission_type = 'daily_free_coin',
      mission_kind = 'custom',
      mission_action = 'custom',
      is_active = TRUE
    WHERE mission_id = v_existing;
  END IF;
END $$;

-- 3) Safety: daily mission claims default to one claim/day.
ALTER TABLE public.missions
  ADD COLUMN IF NOT EXISTS daily_limit INTEGER NOT NULL DEFAULT 1;

UPDATE public.missions
SET daily_limit = 1
WHERE mission_type = 'daily_free_coin';
