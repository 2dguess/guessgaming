-- If house_inflow_queue was created before applied_at existed, CREATE TABLE IF NOT EXISTS
-- would not add this column. Add it idempotently and backfill from updated_at.

ALTER TABLE public.house_inflow_queue
  ADD COLUMN IF NOT EXISTS applied_at TIMESTAMPTZ NULL;

UPDATE public.house_inflow_queue
SET applied_at = updated_at
WHERE status = 'applied'
  AND applied_at IS NULL
  AND updated_at IS NOT NULL;
