# TX AI Market Backend

This is an isolated prototype under `tradingbot/`; it does not modify the existing NaanStock or MindCore modules.

## Current behavior and important limits

- FastAPI API: health, bot status, ticker quotes, candles, paper positions/trades, paper orders, and research report generation.
- `/api/market/quote` requests the public Coinbase Exchange ticker for BTC-USD, ETH-USD, and SOL-USD. If the exchange is unavailable, the endpoint returns a demo value with `status=DEMO` and `source=DEMO FALLBACK · NOT LIVE`.
- `/api/candles` requests public Coinbase hourly candles with the same explicit demo fallback. No Coinbase account token is needed for public market data.
- TX AI embeds the official TradingView hosted chart widget, which gets chart data directly from TradingView; exchange-level real-time access can vary by symbol/venue.
- Paper orders are persisted using SQLAlchemy. Local development defaults to SQLite. For hosted persistence, configure `DATABASE_URL` to a PostgreSQL URL. A free Render PostgreSQL database currently expires after 30 days, and free web services have ephemeral filesystems and sleep after 15 minutes idle. Do not treat a free tier as guaranteed durable or always-on.
- GitHub research report writes are optional and require `GITHUB_RESEARCH_TOKEN` with Contents write access and `GITHUB_RESEARCH_REPO`. Keep the token in hosting secrets, never in the repo or APK. Use a fine-grained token restricted to this repository.
- Set `BOT_API_TOKEN` in hosting. Write endpoints require `Authorization: Bearer <token>` when it is configured.
- No live trading adapter, strategy profitability claim, or autonomous live execution is included.

## Run locally

```bash
cd tradingbot/backend
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
pytest -q
```

Open `/docs` for interactive API docs and `/health` for a health check.

## Free hosting setup (manual action required)

The included `render.yaml` is a starting blueprint. Connect this repository in Render and create the service. Configure `DATABASE_URL` using a PostgreSQL service URL if you need database persistence. Configure `GITHUB_RESEARCH_TOKEN` and `BOT_API_TOKEN` as secrets. The repository file only defines configuration; it does not deploy the service by itself. Test the deployed `/health` endpoint before connecting the APK.

## Android APK

GitHub Actions workflow **Build Paper Trading Bot** runs backend tests and builds a debug APK artifact. The APK's update checker looks for APK assets in GitHub Releases. An Actions artifact is not a Release asset. Publishing a Release and uploading an APK requires a release step. Updating an installed app requires the same application ID and signing certificate; Android may ask the user to confirm installation. The current CI debug signing key is not configured as a persistent signing secret, so seamless in-place APK upgrades are not yet verified.

## Next phases

1. Keep the public ticker clearly marked as LIVE or DEMO, monitor rate limits/staleness, and add a true WebSocket feed only if the polling latency is insufficient.
2. Add strategy engine, backtests with fees/slippage, position sizing, daily loss caps, and deterministic replay tests.
3. Configure persistent hosted PostgreSQL and verify retention across restart/redeploy.
4. Configure a protected, stable Android signing key and publish versioned Release assets.
5. Only after separate review and explicit user approval, consider a live broker adapter; keep paper mode as default and fail closed.


## Alternate deployment providers

The app's provider tiles are dashboard shortcuts, not a completed OAuth connection. Use `tradingbot/backend` as the root directory:
- Build: `pip install -r requirements.txt`
- Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Health check: `/health`

Koyeb is the recommended first attempt for a Git-based FastAPI deployment. Railway is an alternative (check current plan/usage). Google Cloud Run suits containerized services but may require billing setup. Hugging Face Docker Spaces can host demos but may sleep and are not a durable always-on backend. Streamlit Community Cloud is intended for Streamlit apps, not this FastAPI/WebSocket API. Verify the deployed URL with `/health` before entering it in TX AI.
