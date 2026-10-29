#!/usr/bin/env python3
"""Free public-market research scanner. Research only; never places orders."""
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PRODUCT = "BTC-USD"
ENDPOINT = "https://api.exchange.coinbase.com/products/BTC-USD/candles?granularity=3600"


def fetch_candles():
    request = urllib.request.Request(
        ENDPOINT,
        headers={"Accept": "application/json", "User-Agent": "Ai-Hub-PaperResearch/0.1"},
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        rows = json.loads(response.read().decode("utf-8"))
    # Coinbase returns [time, low, high, open, close, volume], newest first.
    candles = [
        {"time": int(row[0]), "low": float(row[1]), "high": float(row[2]),
         "open": float(row[3]), "close": float(row[4]), "volume": float(row[5])}
        for row in rows if isinstance(row, list) and len(row) >= 6
    ]
    candles.sort(key=lambda item: item["time"])
    if len(candles) < 50:
        raise RuntimeError(f"Insufficient candle history: {len(candles)}")
    return candles[-200:]


def average(values):
    return sum(values) / len(values)


def build_report(candles):
    closes = [c["close"] for c in candles]
    sma20 = average(closes[-20:])
    sma50 = average(closes[-50:])
    previous20 = average(closes[-21:-1])
    previous50 = average(closes[-51:-1])
    if previous20 <= previous50 and sma20 > sma50:
        signal = "BULLISH_CROSSOVER_WATCH"
    elif previous20 >= previous50 and sma20 < sma50:
        signal = "BEARISH_CROSSOVER_WATCH"
    else:
        signal = "NO_CROSSOVER"
    latest = candles[-1]
    return {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "symbol": PRODUCT,
        "timeframe": "1h",
        "source": "Coinbase Exchange public market-data API",
        "market_data_is_live": True,
        "candle_count": len(candles),
        "latest_candle_time_utc": datetime.fromtimestamp(latest["time"], timezone.utc).isoformat(),
        "latest_close": round(latest["close"], 2),
        "sma_20": round(sma20, 4),
        "sma_50": round(sma50, 4),
        "signal": signal,
        "execution": "NONE",
        "mode": "RESEARCH_ONLY_PAPER_TRADING",
        "limitations": [
            "A simple moving-average crossover is not a validated strategy.",
            "No fees, slippage, position sizing, or risk-adjusted backtest is included.",
            "This report is not financial advice and must not trigger live orders."
        ]
    }


def main():
    output_dir = Path("tradingbot/research/reports")
    output_dir.mkdir(parents=True, exist_ok=True)
    try:
        report = build_report(fetch_candles())
    except (urllib.error.URLError, TimeoutError, ValueError, RuntimeError, KeyError, TypeError) as exc:
        print(f"Research scan failed safely: {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(2)
    filename = datetime.now(timezone.utc).strftime("scan-%Y%m%dT%H%M%SZ.json")
    path = output_dir / filename
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Created {path}; signal={report['signal']}; no orders placed")


if __name__ == "__main__":
    main()
