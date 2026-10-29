# Research storage

- `scan.py` fetches public 1-hour BTC-USD candles from Coinbase Exchange and creates a small JSON research report.
- `.github/workflows/paper-research-scan.yml` runs on manual dispatch and every six hours after the workflow is present on the repository's default branch.
- The scanner is rule-based SMA20/SMA50 crossover research, **not an AI multi-agent system** and not a proven strategy.
- It never places orders. The report includes source, timestamp, candle count, signal, and limitations.
- A scan fails closed if public market data cannot be fetched or is insufficient; it does not invent live prices.
- GitHub Actions requires repository write permission for the scheduled workflow to commit reports. Review repository Actions permissions if the push step is denied.
