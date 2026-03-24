#!/usr/bin/env bash
# VPS deploy script for kpfk-cms.
# Triggered by GitHub Actions after a successful image push to GHCR.
# Requires on the VPS:
#   - GHCR_USER and GHCR_PAT exported in /etc/environment (or .bashrc for the deploy user)
#   - docker compose v2 installed
#   - /opt/kpfk-cms/docker-compose.yml present

set -euo pipefail

COMPOSE_DIR="/opt/kpfk-cms"
IMAGE="ghcr.io/aestwick/crm:latest"
LOG="$COMPOSE_DIR/deploy.log"
MAX_WAIT=120  # seconds to wait for healthy state

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

log "=== Deploy started ==="

# --- Authenticate to GHCR ---
# GHCR_USER: your GitHub username
# GHCR_PAT:  a GitHub PAT with read:packages scope
if [[ -z "${GHCR_PAT:-}" || -z "${GHCR_USER:-}" ]]; then
  log "ERROR: GHCR_USER and GHCR_PAT must be set in the environment."
  exit 1
fi
echo "$GHCR_PAT" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
log "Authenticated to GHCR"

# --- Pull the new image ---
docker pull "$IMAGE"
log "Pulled $IMAGE"

# --- Restart the stack ---
cd "$COMPOSE_DIR"
docker compose up -d --remove-orphans
log "Stack restarted"

# --- Wait for healthy state ---
log "Waiting for container to be healthy (max ${MAX_WAIT}s)..."
elapsed=0
until [[ "$(docker inspect --format='{{.State.Health.Status}}' kpfk-cms 2>/dev/null)" == "healthy" ]]; do
  if (( elapsed >= MAX_WAIT )); then
    log "ERROR: Container did not become healthy within ${MAX_WAIT}s."
    docker compose logs --tail=50
    exit 1
  fi
  sleep 5
  elapsed=$(( elapsed + 5 ))
done
log "Container is healthy"

# --- Clean up old images ---
docker image prune -f
log "Pruned dangling images"

log "=== Deploy complete ==="
