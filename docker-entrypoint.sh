#!/bin/sh
set -eu

cd /opt/project-maya

MODEL="${MODEL:-Maya-S}"
CONTEXT="${CONTEXT:-32768}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-}"

mkdir -p /data/models

echo "Preparing $MODEL (model files are stored under /data/models)..."

# --no-start lets us complete setup before starting the server.
# --no-vision keeps this initial Docker build text-only.
./maya.sh \
  --setup \
  --model "$MODEL" \
  --context "$CONTEXT" \
  --models-dir /data/models \
  --host 0.0.0.0 \
  --port "$PORT" \
  --api-key "$API_KEY" \
  --no-vision \
  --yes \
  --download-model \
  --no-start

exec ./maya.sh --port "$PORT"
