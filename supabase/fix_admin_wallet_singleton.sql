-- Fix admin wallet drift:
-- - Ensure exactly one row exists in public.admin_wallet
-- - Merge duplicate rows into a single canonical balance (sum)
-- - Enforce singleton with a unique index on constant TRUE

BEGIN;

LOCK TABLE public.admin_wallet IN ACCESS EXCLUSIVE MODE;

DO $$
DECLARE
  keep_id UUID;
  col RECORD;
BEGIN
  -- Ensure table is not empty (safe when singleton index already exists).
  IF NOT EXISTS (SELECT 1 FROM public.admin_wallet) THEN
    INSERT INTO public.admin_wallet DEFAULT VALUES;
  END IF;

  SELECT id INTO keep_id
  FROM public.admin_wallet
  ORDER BY updated_at DESC NULLS LAST, id DESC
  LIMIT 1;

  -- Sum every numeric column into the canonical row (works with any admin_wallet schema).
  FOR col IN
    SELECT a.attname AS column_name
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = 'public'
      AND c.relname = 'admin_wallet'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND t.typcategory = 'N'
  LOOP
    EXECUTE format(
      'UPDATE public.admin_wallet SET %1$I = (SELECT COALESCE(SUM(%1$I),0) FROM public.admin_wallet), updated_at = NOW() WHERE id = $1',
      col.column_name
    )
    USING keep_id;
  END LOOP;

  -- Keep only canonical row.
  DELETE FROM public.admin_wallet WHERE id <> keep_id;
END $$;

DELETE FROM public.admin_wallet aw
WHERE aw.id <> (
  SELECT id
  FROM public.admin_wallet
  ORDER BY updated_at DESC, id DESC
  LIMIT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS admin_wallet_singleton_idx
ON public.admin_wallet ((TRUE));

COMMIT;
