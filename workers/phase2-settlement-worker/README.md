# Phase 2 Settlement Worker (BullMQ)

This worker runs every 60 seconds and processes up to 500 rows from `public.pending_settlements`.

## What it does

1. Claims up to `BATCH_SIZE` queued rows (`status='queued'`) and marks them `processing`.
2. In one DB transaction:
   - inserts `bet_id` into `public.admin_wallet_inflow_applied` (`ON CONFLICT DO NOTHING`) for idempotency
   - credits `public.admin_wallet` by the sum of newly inserted rows only
   - marks claimed queue rows as `applied`
3. If that transaction fails:
   - writes rows into `public.settlement_dead_letter`
   - marks queue rows as `failed` (or re-queues with `next_retry_at`)

## Prerequisites

- Run SQL migrations:
  - `supabase/hybrid_blueprint_phase1_schema_and_reservation.sql`
  - `supabase/hybrid_blueprint_phase2_worker_support.sql`
- Redis reachable from worker runtime
- PostgreSQL connection string with write access

## Run

```bash
cd workers/phase2-settlement-worker
npm install
cp .env.example .env
npm run dev
```

## Docker run (recommended for VM migration)

```bash
cd workers/phase2-settlement-worker
cp .env.example .env
# edit .env with real values
docker compose up -d --build
```

Useful commands:

```bash
docker compose logs -f
docker compose restart
docker compose down
```

## Active/Standby Operations

```bash
chmod +x setup.sh deploy.sh promote.sh demote.sh healthcheck.sh
```

- Promote this VM as active worker:

```bash
./promote.sh
```

- Demote this VM to standby:

```bash
./demote.sh
```

- Quick health check (good for cron/alerts):

```bash
./healthcheck.sh
```

See `OPS_RUNBOOK.md` for active/standby failover flow.

## One-time VM bootstrap

```bash
cd workers/phase2-settlement-worker
chmod +x setup.sh deploy.sh
./setup.sh
# logout/login once so docker group permission applies
```

## One-command deploy (repeat on every update)

```bash
cd workers/phase2-settlement-worker
cp .env.example .env   # first time only
# edit .env with real secrets
./deploy.sh
```

Optional branch override:

```bash
BRANCH=main ./deploy.sh
```

## Move to another VM/account quickly

1. Copy this worker folder (or pull from git).
2. Run `chmod +x setup.sh deploy.sh && ./setup.sh`.
3. Logout/login once.
4. Copy/create `.env`.
5. Run `./deploy.sh`.
6. Update Cloudflare/DNS only if VM IP changed.

## Environment

- `REDIS_URL`
- `DATABASE_URL`
- `BATCH_SIZE` (default `500`)
- `SCHEDULE_EVERY_MS` (default `60000`)
- `MAX_ATTEMPTS` (default `5`)
- `WORKER_CONCURRENCY` (default `1`)
- `SUPABASE_URL` (required for realtime publish)
- `SUPABASE_SERVICE_ROLE_KEY` (required for realtime publish)
- `REALTIME_PROTO_CHANNEL` (default `realtime/betting`)
