# Reusable Railway template for Hermes Agent (Nous Research).
# Pure Nous Research code: only their official install script runs;
# no third-party wrappers in the image.

FROM debian:12-slim

# Minimal bootstrap deps. Everything else is installed by Nous's installer
# (which already knows what Hermes needs and keeps that list current).
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        sudo \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Non-root user. Granted passwordless sudo so the upstream installer
# can run apt for its own dependencies during the build.
ARG HERMES_UID=10001
RUN useradd -m -u "${HERMES_UID}" -s /bin/bash hermes \
    && echo "hermes ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes

USER hermes
ENV HOME=/home/hermes
WORKDIR /home/hermes

# Run the official Nous installer. Pinned to whatever `main` points at
# during image build; rebuild the image to pick up upstream changes.
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

ENV PATH=/home/hermes/.local/bin:${PATH}

# Runtime config & memory live on the Railway volume mounted at /data.
# These can be overridden per-deploy in the Railway dashboard.
ENV HERMES_HOME=/data \
    API_SERVER_ENABLED=true \
    API_SERVER_HOST=0.0.0.0 \
    API_SERVER_PORT=8642 \
    HERMES_TUI=0

EXPOSE 8642

COPY --chown=hermes:hermes entrypoint.sh /home/hermes/entrypoint.sh
RUN chmod +x /home/hermes/entrypoint.sh

ENTRYPOINT ["tini", "--", "/home/hermes/entrypoint.sh"]
