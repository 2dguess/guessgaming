#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${APP_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found"
  exit 1
fi

if [[ ! -f .env ]]; then
  echo ".env not found in ${APP_DIR}"
  exit 1
fi

echo "[promote] starting worker container on this VM..."
docker compose up -d --build
docker compose ps
docker compose logs --tail=80
