#!/usr/bin/env bash
set -euo pipefail

# Stage 1: as root — Railway mounts the volume root-owned. Take ownership for
# the hermes user, then re-exec this same script as hermes.
if [ "$(id -u)" = "0" ]; then
    mkdir -p "${HERMES_HOME}"
    chown -R hermes:hermes "${HERMES_HOME}"
    exec runuser -u hermes -- "$0" "$@"
fi

# Stage 2: running as hermes.
if ! command -v hermes >/dev/null 2>&1; then
    echo "hermes binary not on PATH (PATH=${PATH})" >&2
    exit 1
fi

# First-boot guard. Without LLM credentials, `hermes gateway` exits and the
# container crash-loops, blocking `railway ssh` — which is exactly when the
# operator needs to log in to set credentials up. Idle instead.
if [ ! -s "${HERMES_HOME}/auth.json" ] \
   && [ -z "${OPENROUTER_API_KEY:-}" ] \
   && [ -z "${OPENAI_API_KEY:-}" ] \
   && [ -z "${ANTHROPIC_API_KEY:-}" ] \
   && [ -z "${GOOGLE_API_KEY:-}" ] \
   && [ -z "${GEMINI_API_KEY:-}" ] \
   && [ -z "${OLLAMA_API_KEY:-}" ] \
   && [ -z "${DEEPSEEK_API_KEY:-}" ] \
   && [ -z "${GROQ_API_KEY:-}" ] \
   && [ -z "${XAI_API_KEY:-}" ]; then
    cat >&2 <<EOF
============================================================
Hermes is waiting for first-time setup.

No LLM credentials found:
  - ${HERMES_HOME}/auth.json missing (OAuth providers)
  - No supported *_API_KEY env vars set

To finish setup, either:
  - Set GOOGLE_API_KEY / OPENAI_API_KEY / ANTHROPIC_API_KEY etc.
    in Railway's Variables tab, or
  - For OAuth providers (Codex, Qwen, etc.):
      railway ssh --service hermes-agent
      hermes auth add <provider>

Then:
  railway service redeploy --service hermes-agent

Container is idling so the SSH session above will work.
============================================================
EOF
    exec tail -f /dev/null
fi

# Run the dashboard in the background so the companion workspace service has
# the extended APIs (Sessions, Skills, Config, Jobs). Bound to 0.0.0.0 for
# Railway's internal network; --insecure is the dashboard's own warning that
# it leaves localhost — fine here because Railway only exposes ports we
# explicitly publish, and the workspace authenticates via HERMES_DASHBOARD_TOKEN.
hermes dashboard --host 0.0.0.0 --port 9119 --no-open --insecure \
    > "${HERMES_HOME}/logs/dashboard.stdout.log" 2>&1 &
DASHBOARD_PID=$!
echo "[entrypoint] dashboard started in background (pid=${DASHBOARD_PID})" >&2

# Gateway runs in foreground; the container's lifecycle follows it.
exec hermes gateway
