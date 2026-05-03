# hermes-template-agent

Reusable Railway template for self-hosting the [Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research) behind chat platforms (Telegram, Discord, Slack, etc.).

The image runs only Nous Research's official installer — no third-party wrappers.
The companion web UI lives in a separate repo (`hermes-template-workspace`); deploy it as a second Railway service if you want a browser/mobile dashboard.

## What you get

- A non-root Debian container with Hermes installed via the official Nous installer.
- Persistent config, sessions, and learned skills on a Railway Volume mounted at `/data` (via `HERMES_HOME=/data`).
- The OpenAI-compatible API server (`API_SERVER_ENABLED=true`) listening on `:8642` for the optional workspace service to consume over Railway's private network.
- Auto-update on rebuild: each `railway up` pulls the current `main` of `NousResearch/hermes-agent`.

## Deploy

1. Fork or clone this repo.
2. Create a Railway project, then **New Service → GitHub Repo → this repo**.
3. **Attach a Volume** to the service at mount path `/data` (50 GB is plenty).
4. Set environment variables — see `.env.example` for the full list. Minimum to start:
   - `OPENROUTER_API_KEY` (or any other supported provider)
   - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`
   - `HERMES_TIMEZONE`
   - `HERMES_API_TOKEN` (random 32+ char string; used by the workspace service later)
5. Deploy. First boot takes a few minutes (the installer pulls Hermes and its dependencies).
6. Message your Telegram bot to verify.

Do **not** publicly expose the service's port. The workspace service (Wave 2) talks to it over Railway's private network only.

## Files

- `Dockerfile` — builds the image; runs Nous's official `install.sh`.
- `entrypoint.sh` — claims ownership of the volume on first boot, then `exec hermes gateway`.
- `railway.toml` — Railway build/deploy config.
- `.env.example` — documented per-deploy variables.

## Updating

Rebuild the Railway service to pick up upstream Hermes changes. Pin to a known-good commit by replacing `main` in the Dockerfile's `install.sh` URL with a specific tag/SHA if you want stability over freshness.
