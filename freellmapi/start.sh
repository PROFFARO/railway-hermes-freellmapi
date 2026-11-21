#!/bin/sh
# Start FreeLLMAPI on Railway with its data on the attached volume.
set -e

DATA_DIR="${FREELLMAPI_DATA_DIR:-/data}"
mkdir -p "$DATA_DIR"

if command -v mountpoint >/dev/null 2>&1 && ! mountpoint -q "$DATA_DIR"; then
  echo "WARNING: no Railway volume is mounted at $DATA_DIR."
  echo "         Provider keys and settings will be lost on every redeploy."
fi

# FreeLLMAPI keeps its database and settings in ~/.freellmapi.
# Point that folder at the volume so everything survives restarts and redeploys.
APP_HOME="${HOME:-/root}/.freellmapi"
if [ -L "$APP_HOME" ] || [ ! -e "$APP_HOME" ]; then
  ln -sfn "$DATA_DIR" "$APP_HOME"
else
  echo "WARNING: $APP_HOME already exists as a folder; data may not be stored on the volume."
fi

if [ -z "${ENCRYPTION_KEY:-}" ]; then
  echo "WARNING: ENCRYPTION_KEY is not set. Set a fixed 64-character hex value in Railway"
  echo "         so stored provider keys stay readable after redeploys."
fi

# "::" listens on IPv4 and IPv6, which Railway's private network needs.
export HOST="${HOST:-::}"
export HOST_BIND="${HOST_BIND:-$HOST}"
export PORT="${PORT:-3001}"

echo "--- Starting FreeLLMAPI on [$HOST]:$PORT (data: $DATA_DIR) ---"

if command -v freellmapi >/dev/null 2>&1; then
  exec freellmapi start
else
  exec npx -y freellmapi start
fi
