# Cost Runbook (Plan A / B / C)

This runbook defines practical service choices, estimated monthly cost, and upgrade triggers for the current app stack (social + live viewer + betting).

## 1) Plan Matrix

| Plan | Active Users (concurrent peak) | Core Services / Tools | Estimated Monthly Cost (USD) |
|---|---:|---|---:|
| Plan A (Lean Start) | 1k-10k | Supabase Pro, DO Droplet `$12 x1`, Upstash Redis (small), PM2, Cloudflare (free), k6 | 45-70 |
| Plan B (Stable Growth) | 10k-50k | Supabase Pro, DO `$12 x2` (API + worker split), Redis mid tier, DO LB (optional), PM2, Cloudflare, k6 + alerts | 80-140 |
| Plan C (Scale Path) | 50k-100k | Supabase Pro/upgrade, DO multi-node (`$24 x2~3`), dedicated worker node, Redis high tier, LB + monitoring stack, optional managed realtime (Ably/Pusher) | 180-350+ |

> Notes:
> - Costs are rough baseline ranges and vary by region, traffic pattern, and retention settings.
> - The table is for concurrent active users (not total registered users).

## 2) Per-Plan Service Stack

### Plan A (Low cost, early stage)
- Supabase Pro (`~$25`)
- DigitalOcean Droplet `1 x $12`
- Upstash Redis small (`~$10-20`)
- Cloudflare Free (`$0`)
- Tools: PM2, k6, basic monitoring

### Plan B (Best cost/stability balance)
- Supabase Pro (`~$25`)
- DigitalOcean `2 x $12` (`$24`) - split API and worker
- Redis mid tier (`$20-50`)
- DO Load Balancer optional (`~$12`)
- Monitoring/logs (`$10-20`)
- Tools: PM2, k6 staged load, Slack/Telegram alert hooks

### Plan C (High concurrency path)
- Supabase Pro or higher
- DO app nodes (`$24 x2~3`) + dedicated worker node
- Redis high tier (`$50-150`)
- LB + observability stack
- Optional managed realtime (Ably/Pusher) for high fanout sockets
- Tools: runbooks, autoscale scripts, canary + rollback process

## 3) Upgrade Triggers (A -> B, B -> C)

Upgrade when **2 or more** signals remain unhealthy for **10-15 minutes**:

- API p95 latency above target
- Realtime lag above target
- Queue backlog continuously rising
- Decode error rate / fallback rate above threshold
- Failed jobs or DLQ spikes above baseline
- Any reconciliation mismatch not self-healed quickly

## 4) Trigger Response SOP

1. Verify: Confirm metrics in dashboard (same time window + env)
2. Notify: Post incident update to team channel
3. Execute: Apply scaling action from runbook
4. Monitor: Watch for 30 minutes to confirm recovery
5. Closeout: Record root cause + preventive action

## 5) Hard-Stop Escalation Conditions

Escalate immediately (do not wait 10-15 minutes) if:

- reconciliation mismatch > 0 and growing
- user-facing 5xx/timeout spikes
- payout/settlement failures increase rapidly
- worker queue stuck in processing without drain

## 6) Operating Rules for Low Cost + Stability

- Scale by metrics, not guesses
- Keep DB as source of truth for critical betting correctness
- Use queue + batch processing for heavy writes
- Use Redis for cache and fanout assistance
- Keep JSON fallback path for emergency protobuf issues

