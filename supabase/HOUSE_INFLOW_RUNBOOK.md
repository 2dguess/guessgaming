# House Inflow Worker Runbook

This runbook is for operating queue-based house inflow safely in production.

## 1) Golden Baseline

- Throughput target: `>= 278 rows/sec` (1M rows/hour)
- Drift must stay zero:
  - `locked_drift = 0`
  - `admin_vs_shard_drift = 0`

Health query:

```sql
SELECT * FROM public.house_pool_health;
```

---

## 2) Worker Payload Presets

### Normal traffic

```json
{"limit":50000,"loops":12,"sleepMs":1000,"requeueAfterSeconds":30}
```

### Peak traffic

```json
{"limit":100000,"loops":30,"sleepMs":500,"requeueAfterSeconds":30}
```

### Extreme traffic (short burst)

```json
{"limit":100000,"loops":60,"sleepMs":200,"requeueAfterSeconds":30}
```

Use 2-3 parallel invocations in peak windows if needed.

---

## 3) Core Monitoring

Queue snapshot:

```sql
SELECT * FROM public.house_inflow_queue_kpi;
```

Last-hour throughput:

```sql
SELECT * FROM public.house_inflow_last_hour;
```

Error top:

```sql
SELECT * FROM public.house_inflow_error_top;
```

10-minute rows/sec:

```sql
SELECT
  COUNT(*) FILTER (
    WHERE status='applied'
      AND COALESCE(applied_at, updated_at, created_at) >= NOW() - INTERVAL '10 minutes'
  ) AS applied_rows_10m,
  ROUND(
    (
      COUNT(*) FILTER (
        WHERE status='applied'
          AND COALESCE(applied_at, updated_at, created_at) >= NOW() - INTERVAL '10 minutes'
      )
    ) / 600.0
  , 2) AS rows_per_sec_10m
FROM public.house_inflow_queue;
```

---

## 4) Alert Thresholds

- `failed_rows_1h > 0` -> investigate immediately
- `queued_rows` growing for > 10 min -> increase worker intensity/parallelism
- `rows_per_sec_10m < 278` during 1M/h target windows -> scale worker
- any drift non-zero -> run reconcile

---

## 5) Emergency Recovery

Requeue stuck processing rows:

```sql
UPDATE public.house_inflow_queue
SET status='queued', updated_at=NOW(), error_message=COALESCE(error_message, 'manual requeue')
WHERE status='processing';
```

Reset failed rows for retry:

```sql
UPDATE public.house_inflow_queue
SET status='queued', attempts=0, error_message=NULL, updated_at=NOW()
WHERE status='failed';
```

Sync wallet and shard totals:

```sql
SELECT public.reconcile_house_pool(TRUE);
SELECT * FROM public.house_pool_health;
```

---

## 6) Quick Validation Checklist

1. Worker invoke returns `ok: true`
2. `processed/applied` moves > 0 when queue exists
3. `failed_marked = 0` in normal runs
4. `pending_inflow_total` trends down to 0
5. `locked_drift = 0` and `admin_vs_shard_drift = 0`

