#!/usr/bin/env bash
set -euo pipefail

# On first deploy the Railway volume is empty and may be owned by root.
# Take ownership so Hermes can write its config, sessions, and learned skills.
if [ -d "${HERMES_HOME}" ] && [ "$(stat -c '%u' "${HERMES_HOME}")" != "$(id -u)" ]; then
    sudo chown -R "$(id -u):$(id -g)" "${HERMES_HOME}"
fi
mkdir -p "${HERMES_HOME}"

if ! command -v hermes >/dev/null 2>&1; then
    echo "hermes binary not on PATH (PATH=${PATH})" >&2
    exit 1
fi

exec hermes gateway
