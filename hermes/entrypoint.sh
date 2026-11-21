#!/bin/bash
# Railway wrapper for the official Hermes Agent image.
# Prepares settings on the volume, connects Hermes to FreeLLMAPI, then hands over to the
# image's own entrypoint (s6 supervision, volume ownership fixes, privilege drop).

export PATH="/command:/package/admin/s6/command:/usr/local/bin:$PATH"

DATA_DIR="${HERMES_HOME:-/opt/data}"
CONFIG="$DATA_DIR/config.yaml"
mkdir -p "$DATA_DIR"

echo "--- Hermes Agent on Railway ---"

# 1. Make sure memory is on a Railway volume
if command -v mountpoint >/dev/null 2>&1 && ! mountpoint -q "$DATA_DIR"; then
  echo "WARNING: no Railway volume is mounted at $DATA_DIR."
  echo "         Memories, sessions and settings will be lost on every redeploy."
fi

# 2. Refuse to start with an unprotected public dashboard or API
fail=0
if [ "${HERMES_DASHBOARD:-1}" = "1" ] \
  && [ -z "${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}" ] \
  && [ -z "${HERMES_DASHBOARD_OAUTH_CLIENT_ID:-}" ]; then
  echo "ERROR: the dashboard has no sign-in configured."
  echo "       Set HERMES_DASHBOARD_BASIC_AUTH_USERNAME and HERMES_DASHBOARD_BASIC_AUTH_PASSWORD"
  echo "       (or HERMES_DASHBOARD_OAUTH_CLIENT_ID) in Railway, or set HERMES_DASHBOARD=0."
  fail=1
fi
if [ "${API_SERVER_ENABLED:-false}" = "true" ] && [ -z "${API_SERVER_KEY:-}" ]; then
  echo "ERROR: API_SERVER_KEY is not set. Add it in Railway, or set API_SERVER_ENABLED=false."
  fail=1
fi
[ "$fail" -eq 1 ] && exit 1

# 3. Connect Hermes to FreeLLMAPI over Railway's private network
BASE_URL="${FREELLMAPI_BASE_URL:-http://freellmapi.railway.internal:3001/v1}"
export OPENAI_BASE_URL="$BASE_URL"
echo "Model endpoint: $BASE_URL"

if [ -n "${FREELLMAPI_KEY:-}" ]; then
  export OPENAI_API_KEY="$FREELLMAPI_KEY"
else
  echo "NOTICE: FREELLMAPI_KEY is not set yet. Hermes will start, but it can't answer until you"
  echo "        add the unified key from the FreeLLMAPI dashboard to this service's variables."
fi

# 4. Write the model settings on first boot (or when HERMES_RESET_CONFIG=true).
#    The image fills in every other default and migrates the file automatically.
if [ ! -f "$CONFIG" ] || [ "${HERMES_RESET_CONFIG:-false}" = "true" ]; then
  if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Existing config.yaml backed up before reset."
  fi
  cat > "$CONFIG" <<EOF
model:
  provider: custom
  default: ${HERMES_MODEL:-auto}
  base_url: ${BASE_URL}
terminal:
  backend: local
EOF
  echo "Wrote model settings to $CONFIG"
else
  echo "Keeping existing $CONFIG (set HERMES_RESET_CONFIG=true once to rewrite the model settings)."
fi

# Hand the volume to the hermes user (the image also does this on boot)
chown -R "${HERMES_UID:-10000}:${HERMES_GID:-10000}" "$DATA_DIR" 2>/dev/null || true

# 5. Start Hermes through the image's own dispatcher so s6 stays PID 1
exec /opt/hermes/docker/entrypoint-dispatch.sh gateway run
