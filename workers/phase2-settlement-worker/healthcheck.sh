#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${APP_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "CRIT: docker not installed"
  exit 2
fi

status="$(docker compose ps --status running --services 2>/dev/null || true)"
if [[ "${status}" != *"phase2-settlement-worker"* ]]; then
  echo "CRIT: phase2-settlement-worker is not running"
  exit 2
fi

recent_logs="$(docker compose logs --tail=120 2>/dev/null || true)"
if echo "${recent_logs}" | grep -Eq "ECONNREFUSED|WRONGPASS|ENOENT|fatal startup error"; then
  echo "CRIT: runtime errors detected"
  exit 2
fi

if ! echo "${recent_logs}" | grep -q "started queue=phase2-settlement-batch"; then
  echo "WARN: startup marker not found in recent logs"
  exit 1
fi

echo "OK: worker healthy"
exit 0
