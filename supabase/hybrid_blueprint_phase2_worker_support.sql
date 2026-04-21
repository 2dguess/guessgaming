-- Hybrid Blueprint - Phase 2 support objects
-- Run this before starting the Node/BullMQ worker.

-- Idempotency ledger for admin wallet inflow apply.
-- One bet_id can credit admin wallet at most once.
CREATE TABLE IF NOT EXISTS public.admin_wallet_inflow_applied (
  bet_id UUID PRIMARY KEY REFERENCES public.bets(bet_id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount > 0),
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_wallet_inflow_applied_applied_at
ON public.admin_wallet_inflow_applied(applied_at DESC);

ALTER TABLE public.admin_wallet_inflow_applied ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read admin wallet inflow applied" ON public.admin_wallet_inflow_applied;
CREATE POLICY "Admins can read admin wallet inflow applied"
  ON public.admin_wallet_inflow_applied FOR SELECT
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "No direct insert admin wallet inflow applied" ON public.admin_wallet_inflow_applied;
CREATE POLICY "No direct insert admin wallet inflow applied"
  ON public.admin_wallet_inflow_applied FOR INSERT
  WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No direct update admin wallet inflow applied" ON public.admin_wallet_inflow_applied;
CREATE POLICY "No direct update admin wallet inflow applied"
  ON public.admin_wallet_inflow_applied FOR UPDATE
  USING (FALSE);
