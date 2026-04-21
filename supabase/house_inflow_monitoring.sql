-- Monitoring queries for house inflow queue worker.
-- Read-only helpers for quick health checks.

-- =========================================================
-- 1) Queue KPI snapshot (overall)
-- =========================================================
CREATE OR REPLACE VIEW public.house_inflow_queue_kpi AS
SELECT
  COUNT(*)::BIGINT AS total_rows,
  COUNT(*) FILTER (WHERE status = 'queued')::BIGINT AS queued_rows,
  COUNT(*) FILTER (WHERE status = 'processing')::BIGINT AS processing_rows,
  COUNT(*) FILTER (WHERE status = 'applied')::BIGINT AS applied_rows,
  COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed_rows,
  COALESCE(SUM(amount) FILTER (WHERE status IN ('queued', 'processing')), 0)::BIGINT AS pending_amount,
  COALESCE(SUM(amount) FILTER (WHERE status = 'applied'), 0)::BIGINT AS applied_amount
FROM public.house_inflow_queue;

-- =========================================================
-- 2) Last 1 hour throughput / failures
-- =========================================================
CREATE OR REPLACE VIEW public.house_inflow_last_hour AS
SELECT
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour')::BIGINT AS enqueued_rows_1h,
  COALESCE(SUM(amount) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour'), 0)::BIGINT AS enqueued_amount_1h,
  COUNT(*) FILTER (WHERE applied_at >= NOW() - INTERVAL '1 hour')::BIGINT AS applied_rows_1h,
  COALESCE(SUM(amount) FILTER (WHERE applied_at >= NOW() - INTERVAL '1 hour'), 0)::BIGINT AS applied_amount_1h,
  COUNT(*) FILTER (
    WHERE status = 'failed'
      AND created_at >= NOW() - INTERVAL '1 hour'
  )::BIGINT AS failed_rows_1h
FROM public.house_inflow_queue;

-- =========================================================
-- 3) Top current errors (if any)
-- =========================================================
CREATE OR REPLACE VIEW public.house_inflow_error_top AS
SELECT
  COALESCE(NULLIF(TRIM(error_message), ''), '(empty)') AS error_message,
  COUNT(*)::BIGINT AS occurrences,
  MAX(created_at) AS latest_at
FROM public.house_inflow_queue
WHERE status = 'failed'
GROUP BY COALESCE(NULLIF(TRIM(error_message), ''), '(empty)')
ORDER BY occurrences DESC, latest_at DESC
LIMIT 20;

-- Quick usage:
-- SELECT * FROM public.house_inflow_queue_kpi;
-- SELECT * FROM public.house_inflow_last_hour;
-- SELECT * FROM public.house_inflow_error_top;

