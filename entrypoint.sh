#!/usr/bin/env bash
set -euo pipefail

if [ -d "${HERMES_HOME}" ] && [ "$(stat -c '%u' "${HERMES_HOME}")" != "$(id -u)" ]; then
    sudo chown -R "$(id -u):$(id -g)" "${HERMES_HOME}"
fi
mkdir -p "${HERMES_HOME}"

if ! command -v hermes >/dev/null 2>&1; then
    echo "hermes binary not on PATH (PATH=${PATH})" >&2
    exit 1
fi

# First-boot guard. Without LLM credentials, `hermes gateway` exits
# immediately and the container crash-loops, blocking `railway ssh` —
# which is exactly when the operator needs to log in to set credentials up.
# Idle instead so the operator can shell in and run `hermes auth login`.
if [ ! -s "${HERMES_HOME}/auth.json" ] \
   && [ -z "${OPENROUTER_API_KEY:-}" ] \
   && [ -z "${OPENAI_API_KEY:-}" ] \
   && [ -z "${ANTHROPIC_API_KEY:-}" ] \
   && [ -z "${OLLAMA_API_KEY:-}" ]; then
    cat >&2 <<EOF
============================================================
Hermes is waiting for first-time setup.

No LLM credentials found:
  - ${HERMES_HOME}/auth.json missing (OAuth providers)
  - No OPENROUTER_API_KEY / OPENAI_API_KEY / ANTHROPIC_API_KEY
    / OLLAMA_API_KEY environment variables set

To finish setup:
  1. railway ssh --service hermes-agent
  2. hermes auth login \${HERMES_INFERENCE_PROVIDER:-openai-codex}
  3. railway redeploy --service hermes-agent

Container is idling so the SSH session above will work.
============================================================
EOF
    exec tail -f /dev/null
fi

exec hermes gateway
