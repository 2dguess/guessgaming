## Payout Worker

Processes due payout jobs created by `admin_prepare_batched_payout`.

### Deploy

```bash
supabase functions deploy payout-worker --no-verify-jwt
```

### Required env vars

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PAYOUT_WORKER_CRON_SECRET`
- `PAYOUT_WORKER_DEFAULT_LIMIT` (optional, default `2000`)
- `PAYOUT_WORKER_MAX_ATTEMPTS` (optional, default `5`)

### Request

`POST /functions/v1/payout-worker`

Headers:
- `x-cron-secret: <PAYOUT_WORKER_CRON_SECRET>`
- `content-type: application/json`

Body (optional):

```json
{
  "limit": 2000,
  "maxAttempts": 5
}
```

### Recommended trigger frequency

- Every 1 minute (minimum cron granularity)
- If payout load is high, run parallel invocations with safe limits or increase `limit`.

