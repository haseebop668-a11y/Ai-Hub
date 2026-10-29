# TX AI connection and APK release setup

## Current verified boundary

- The app is branded TX AI. The backend requests public Coinbase hourly candles for BTC-USD, ETH-USD, and SOL-USD, and falls back to explicitly labeled demo candles if unavailable. Paper orders use the latest public quote when available, but remain simulated; no exchange order is sent.
- A real FastAPI URL does not exist until the Render service is created and deployed. The top-level `render.yaml` is a Render Blueprint template; it does not deploy itself. Create a Blueprint in Render and connect this repository once.
- The app's update checker reads the latest GitHub Release and offers the APK download. GitHub Actions artifacts are not Releases.
- GitHub OAuth cannot be enabled safely by adding a button alone. It needs a registered OAuth App, a callback endpoint, and server-side token exchange. Do not embed a GitHub client secret or personal access token in the APK.
- Never paste exchange API secrets into the app's GitHub connection or commit secrets to this repository.

## Deploy the backend

1. Sign in to Render and create a Blueprint deployment from `haseebop668-a11y/Ai-Hub`; select the repository's top-level `render.yaml`.
2. The Blueprint creates a free web service with public Coinbase market data and a generated `BOT_API_TOKEN`. This SQLite-first configuration is for smoke-testing; Render's free filesystem is ephemeral, so paper trade history can be lost on restart/redeploy.
3. After deployment, copy the actual service URL from Render and test `/health`, `/api/market/quote?symbol=BTC-USD`, and `/docs`. Replace the example host with the real host.
4. In the APK, enter the service base URL only (no `/health` suffix). Public market data endpoints do not require the bearer token; paper-order writes still require the generated token until a proper user login/session flow is implemented.
5. For durable paper trading, configure an external PostgreSQL database by setting `DATABASE_URL` in Render, then verify rows survive restart/redeploy.

No live service URL can be claimed until deployment and the health endpoint have been checked.

## Stable APK updates

The current installed debug APK may not accept an update signed by a different key. The in-app update button can download an official APK from the GitHub Release; Android still requires the user to confirm installation. The app must be signed with the same release key for in-place updates. Before enabling repeatable in-place updates, create one Android release keystore and keep it backed up privately. Add these GitHub Actions repository secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded keystore bytes
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Do not commit the keystore or passwords. The workflow `.github/workflows/release-paper-trading-bot.yml` requires these secrets, runs tests, builds and verifies a signed APK, and publishes it as a GitHub Release when a `txai-v*` tag is pushed or the workflow is manually run. The same signing key must be retained for every future release. If the current phone APK uses a different debug key, uninstalling it and installing the first signed release may be necessary; this can erase app-local settings.

## Broker connection

A private broker integration is a separate feature and is not currently implemented. Coinbase's public candle endpoint requires no API token and does not authorize account access or order placement. For any future live order execution, select a specific broker and configure API credentials as server-side secrets with withdrawals disabled, explicit user opt-in, and fail-closed controls. Any future live broker adapter must use server-side secrets, explicit opt-in, and fail-closed controls; never put exchange API secrets in the APK. No broker token should be entered until a specific provider and secure server-side integration are implemented.
