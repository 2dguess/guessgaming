## House Inflow Worker

Processes `house_inflow_queue` in high-throughput batches.

This worker supports "5-second equivalent" mode by looping inside one invocation.
Example: `loops=12` and `sleepMs=5000` ~= 60 seconds with 12 processing passes.

### Deploy

```bash
supabase functions deploy house-inflow-worker --no-verify-jwt
```

### Required env vars

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `HOUSE_INFLOW_WORKER_CRON_SECRET`
- `HOUSE_INFLOW_WORKER_DEFAULT_LIMIT` (optional, default `50000`)
- `HOUSE_INFLOW_WORKER_MAX_ATTEMPTS` (optional, default `5`)
- `HOUSE_INFLOW_WORKER_LOOPS` (optional, default `12`)
- `HOUSE_INFLOW_WORKER_SLEEP_MS` (optional, default `5000`)

### Request

`POST /functions/v1/house-inflow-worker`

Headers:
- `x-cron-secret: <HOUSE_INFLOW_WORKER_CRON_SECRET>`
- `content-type: application/json`

Body (optional):

```json
{
  "limit": 50000,
  "maxAttempts": 5,
  "loops": 12,
  "sleepMs": 5000
}
```

### Recommended production pattern

- Trigger every 1 minute from scheduler.
- Use loop mode for sub-minute processing:
  - `loops = 12`
  - `sleepMs = 5000`
- For very high traffic, run 2 parallel triggers with same payload
  (safe due to `FOR UPDATE SKIP LOCKED` in queue processor).

