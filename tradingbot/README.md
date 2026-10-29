# Ai-Hub Trading Bot — Paper Trading MVP

This project lives only in `haseebop668-a11y/Ai-Hub/tradingbot/`.

## Components
- `backend/`: FastAPI, SQLAlchemy persistence, paper-only order API, health endpoint, optional GitHub research JSON writer.
- `mobile/`: Android WebView shell with responsive dark candlestick dashboard and GitHub Releases update checker.
- `.github/workflows/build-paper-trading-bot.yml`: automated backend tests and Android debug APK build.

## Safety and status
- Paper trading only. The backend has no live broker integration.
- Chart candles and order quotes are clearly marked as synthetic demo data, not real market prices.
- UI shows paper positions and recent trade ledger. P&L is a placeholder and is not a verified portfolio calculation.
- GitHub research file writes are opt-in through a repository-scoped token held in hosting secrets.
- Free hosting is suitable for a prototype only; it cannot guarantee continuous execution. See `backend/README.md`.

## Build
Run the **Build Paper Trading Bot** workflow from the repository Actions tab. A successful run will upload a `paper-trading-bot-debug-apk` artifact. This is a debug APK artifact, not a signed public release. The workflow must actually pass before claiming a build succeeded.
