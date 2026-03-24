#!/usr/bin/env bash
set -euo pipefail

cd /opt/kpfk-donate-next

echo "Pulling latest image(s)..."
docker compose pull

echo "Restarting containers..."
docker compose up -d

echo "Done. Current status:"
docker compose ps
