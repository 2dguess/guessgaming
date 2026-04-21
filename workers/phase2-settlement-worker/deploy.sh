#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${APP_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Run ./setup.sh first."
  exit 1
fi

if [[ ! -f .env ]]; then
  echo ".env not found. Create it first:"
  echo "cp .env.example .env"
  exit 1
fi

if [[ -d .git ]]; then
  BRANCH="${BRANCH:-main}"
  echo "[deploy] Updating code from git branch ${BRANCH}..."
  git fetch --all --prune
  git checkout "${BRANCH}"
  git pull --ff-only origin "${BRANCH}"
fi

echo "[deploy] Building and starting containers..."
docker compose up -d --build

echo "[deploy] Current status:"
docker compose ps

echo "[deploy] Recent logs:"
docker compose logs --tail=50
