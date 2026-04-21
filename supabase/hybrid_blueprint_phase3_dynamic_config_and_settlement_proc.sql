-- Hybrid Blueprint - Phase 3
-- Dynamic config + settlement logs + ACID-safe settlement procedure

-- =========================================================
-- 1) Dynamic system config
-- =========================================================
CREATE TABLE IF NOT EXISTS public.system_config (
  id BIGSERIAL PRIMARY KEY,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  current_user_count BIGINT NOT NULL DEFAULT 0,
  batch_size INTEGER NOT NULL DEFAULT 5000,
  frequency_seconds INTEGER NOT NULL DEFAULT 60,
  max_attempts INTEGER NOT NULL DEFAULT 5,
  updated_by UUID NULL REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (batch_size > 0),
  CHECK (frequency_seconds > 0),
  CHECK (max_attempts > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_system_config_active_true
ON public.system_config ((is_active))
WHERE is_active = TRUE;

INSERT INTO public.system_config (is_active, current_user_count, batch_size, frequency_seconds, max_attempts)
SELECT TRUE, 0, 5000, 60, 5
WHERE NOT EXISTS (
  SELECT 1 FROM public.system_config WHERE is_active = TRUE
);

-- =========================================================
-- 2) Settlement logs
-- =========================================================
CREATE TABLE IF NOT EXISTS public.settlement_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('info', 'warn', 'error')),
  stage TEXT NOT NULL,
  message TEXT NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settlement_logs_run
ON public.settlement_logs(run_id, created_at DESC);

-- =========================================================
-- 3) Redis vs Postgres reconciliation logs
-- =========================================================
CREATE TABLE IF NOT EXISTS public.balance_reconciliation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pg_balance BIGINT NOT NULL,
  redis_balance BIGINT NOT NULL,
  delta BIGINT NOT NULL,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  note TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_balance_recon_checked
ON public.balance_reconciliation_logs(checked_at DESC);

-- =========================================================
-- 4) ACID-safe settlement procedure
--    - Uses FOR UPDATE SKIP LOCKED
--    - Uses admin_wallet_inflow_applied for idempotent credit
--    - Inserts logs into settlement_logs
-- =========================================================
CREATE OR REPLACE PROCEDURE public.settle_admin_wallet_hybrid()
LANGUAGE plpgsql
AS $$
DECLARE
  v_cfg RECORD;
  v_run_id UUID := gen_random_uuid();
  v_claimed INTEGER := 0;
  v_applied INTEGER := 0;
  v_admin_delta BIGINT := 0;
BEGIN
  SELECT batch_size, frequency_seconds, max_attempts
  INTO v_cfg
  FROM public.system_config
  WHERE is_active = TRUE
  ORDER BY updated_at DESC
  LIMIT 1;

  IF v_cfg IS NULL THEN
    INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
    VALUES (
      v_run_id,
      'error',
      'config',
      'No active system_config found',
      '{}'::JSONB
    );
    RAISE EXCEPTION 'No active system_config found';
  END IF;

  CREATE TEMP TABLE _picked_settlement ON COMMIT DROP AS
  SELECT q.queue_id, q.bet_id, q.amount
  FROM public.pending_settlements q
  WHERE q.status = 'queued'
    AND (q.next_retry_at IS NULL OR q.next_retry_at <= NOW())
  ORDER BY q.created_at ASC
  LIMIT v_cfg.batch_size
  FOR UPDATE SKIP LOCKED;

  GET DIAGNOSTICS v_claimed = ROW_COUNT;

  IF v_claimed = 0 THEN
    INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
    VALUES (
      v_run_id,
      'info',
      'claim',
      'No queued settlements found',
      jsonb_build_object('batch_size', v_cfg.batch_size)
    );
    RETURN;
  END IF;

  UPDATE public.pending_settlements q
  SET
    status = 'processing',
    attempts = attempts + 1,
    updated_at = NOW()
  WHERE q.queue_id IN (SELECT p.queue_id FROM _picked_settlement p)
    AND q.status = 'queued';

  WITH inserted AS (
    INSERT INTO public.admin_wallet_inflow_applied (bet_id, amount, applied_at)
    SELECT p.bet_id, p.amount, NOW()
    FROM _picked_settlement p
    ON CONFLICT (bet_id) DO NOTHING
    RETURNING amount
  )
  SELECT COALESCE(SUM(i.amount), 0)::BIGINT INTO v_admin_delta
  FROM inserted i;

  INSERT INTO public.admin_wallet (balance, updated_at)
  SELECT 0, NOW()
  WHERE NOT EXISTS (SELECT 1 FROM public.admin_wallet);

  IF v_admin_delta > 0 THEN
    UPDATE public.admin_wallet a
    SET
      balance = a.balance + v_admin_delta,
      updated_at = NOW()
    WHERE a.id = (
      SELECT id
      FROM public.admin_wallet
      ORDER BY updated_at DESC
      LIMIT 1
      FOR UPDATE
    );
  END IF;

  UPDATE public.pending_settlements q
  SET
    status = 'applied',
    applied_at = NOW(),
    updated_at = NOW(),
    error_message = NULL
  WHERE q.queue_id IN (SELECT p.queue_id FROM _picked_settlement p)
    AND q.status = 'processing';

  GET DIAGNOSTICS v_applied = ROW_COUNT;

  INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
  VALUES (
    v_run_id,
    'info',
    'apply',
    'Settlement batch applied',
    jsonb_build_object(
      'claimed_rows', v_claimed,
      'applied_rows', v_applied,
      'admin_delta', v_admin_delta
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO public.settlement_logs (run_id, level, stage, message, meta)
    VALUES (
      v_run_id,
      'error',
      'exception',
      SQLERRM,
      jsonb_build_object('sqlstate', SQLSTATE)
    );
    RAISE;
END;
$$;

