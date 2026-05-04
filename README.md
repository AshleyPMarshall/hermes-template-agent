# hermes-template-agent

Reusable Railway template for self-hosting the [Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research) behind chat platforms (Telegram, Discord, Slack, etc.).

The image runs only Nous Research's official installer — no third-party wrappers.
The companion web UI lives in a separate repo (`hermes-template-workspace`); deploy it as a second Railway service if you want a browser/mobile dashboard.

## What you get

- A non-root Debian container with Hermes installed via the official Nous installer.
- Persistent config, sessions, and learned skills on a Railway Volume mounted at `/data` (via `HERMES_HOME=/data`).
- The OpenAI-compatible API server on `:8642` and the Hermes dashboard on `:9119`, both bound to the container's interface for the optional workspace service to consume over Railway's private network. Neither is publicly exposed unless you create a Railway domain for that port.
- Auto-update on rebuild: each `railway up` pulls the current `main` of `NousResearch/hermes-agent`.

## Deploy

Each deployment is isolated — env vars live on the Railway service, not in this repo.
You will create new credentials *per deployment*; nothing from another deployment carries over.

### First-time setup checklist

1. **Fork or clone** this repo into your GitHub account.
2. **Create a new Railway project**, then **New Service → GitHub Repo → your fork**.
3. **Create a Railway Volume** in the same project, attach to this service at mount path `/data` (50 GB is plenty).
4. **Create a fresh Telegram bot** via [@BotFather](https://t.me/BotFather) (`/newbot`) — do not reuse a bot from another deployment.
5. **Get your Telegram numeric user ID** from [@userinfobot](https://t.me/userinfobot).
6. **Generate a fresh `HERMES_API_TOKEN`**: `openssl rand -hex 32`. The companion workspace service uses this; do not reuse it across deployments.
7. **Set environment variables** in Railway. Minimum:
   - `GOOGLE_API_KEY` (default — Gemini, free tier at https://aistudio.google.com/app/apikey)
   - `HERMES_MODEL=gemini-2.5-flash`
   - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`
   - `HERMES_TIMEZONE`
   - `API_SERVER_KEY` and `HERMES_DASHBOARD_TOKEN` (each: `openssl rand -hex 32`) — bearer tokens the workspace service authenticates with
   See `.env.example` for the complete list and notes on swapping providers.
8. **Deploy.** First boot takes 5–10 minutes (Nous installer pulls Hermes and dependencies).
9. **(OAuth providers only — skip for static API keys.)** If you chose an OAuth provider (Codex, Qwen, etc.) instead of a static API key, complete the device-code flow:
   ```
   railway ssh --service hermes-agent
   hermes auth add <provider>            # e.g. openai-codex, qwen-oauth
   ```
   The token writes to `/data/auth.json` and persists across redeploys.
10. **Redeploy the service** (`railway service redeploy`) so the agent picks up the new credentials.
11. **Message your Telegram bot** to verify.

The container idles on first boot if no LLM credentials are present (no `auth.json`, no API key env vars), so you have time to step 9 without crash-loops.

Do **not** publicly expose the service's port. The workspace service (Wave 2) talks to it over Railway's private network only.

## Files

- `Dockerfile` — builds the image; runs Nous's official `install.sh`.
- `entrypoint.sh` — claims ownership of the volume on first boot, then runs `hermes dashboard` in the background and `hermes gateway` in the foreground.
- `railway.toml` — Railway build/deploy config.
- `.env.example` — documented per-deploy variables.

## Updating

Rebuild the Railway service to pick up upstream Hermes changes. Pin to a known-good commit by replacing `main` in the Dockerfile's `install.sh` URL with a specific tag/SHA if you want stability over freshness.
