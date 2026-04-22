# Phase2 Worker Ops Runbook

## Topology

- `worker-1`: active node (runs the worker).
- `api-1`: standby node (kept down unless failover is needed).
- Rule: keep only one node active at a time.

## Daily Deploy (active node)

```bash
cd ~/guessgaming
git pull
cd workers/phase2-settlement-worker
./deploy.sh
./healthcheck.sh
```

## Standby Update

```bash
cd ~/guessgaming
git pull
cd workers/phase2-settlement-worker
./demote.sh
```

## Failover (promote standby)

On standby node:

```bash
cd ~/guessgaming/workers/phase2-settlement-worker
./promote.sh
./healthcheck.sh
```

Then demote the old active node:

```bash
cd ~/guessgaming/workers/phase2-settlement-worker
./demote.sh
```

## Rollback

```bash
cd ~/guessgaming
git log --oneline -n 5
git checkout <known-good-commit>
cd workers/phase2-settlement-worker
./deploy.sh
./healthcheck.sh
```

## Weekly Checklist

1. Verify active node health with `./healthcheck.sh`.
2. Ensure standby node is down with `./demote.sh`.
3. Check recent logs for worker errors.
4. Run a manual failover drill once.
5. Clean docker artifacts monthly (`docker image prune -f`).

