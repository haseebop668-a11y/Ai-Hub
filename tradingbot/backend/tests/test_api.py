import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Each test run gets an isolated SQLite database.
db_file = Path(__file__).parent / "test_tradingbot.db"
os.environ["DATABASE_URL"] = f"sqlite:///{db_file}"
os.environ.pop("BOT_API_TOKEN", None)
os.environ["MARKET_DATA_PROVIDER"] = "demo"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import main  # noqa: E402

client = TestClient(main.app)


def setup_function():
    main.Base.metadata.drop_all(main.engine)
    main.Base.metadata.create_all(main.engine)


def test_health_reports_paper_and_demo_only():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["database"] is True
    assert response.json()["mode"] == "paper-only"
    assert response.json()["market_data"] == "coinbase-public-with-demo-fallback"


def test_live_quote_endpoint_labels_demo_fallback():
    response = client.get("/api/market/quote?symbol=BTC-USD")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "DEMO"
    assert payload["source"] == "DEMO FALLBACK · NOT LIVE"
    assert payload["price"] > 0


def test_quote_reports_live_when_public_ticker_is_available(monkeypatch):
    monkeypatch.setattr(main, "coinbase_quote", lambda symbol: {
        "symbol": symbol, "price": 65000.25, "bid": 65000.0, "ask": 65000.5,
        "volume_24h": 1234.5, "timestamp": "2026-10-29T10:00:00Z",
    })
    response = client.get("/api/market/quote?symbol=BTC-USD")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "LIVE"
    assert payload["source"] == "COINBASE LIVE · PUBLIC TICKER"
    assert payload["price"] == pytest.approx(65000.25)


def test_candles_are_valid_ohlc_and_explicitly_demo():
    payload = client.get("/api/candles?symbol=BTC-USD&limit=20").json()
    assert payload["source"] == "DEMO FALLBACK · NOT LIVE"
    assert len(payload["candles"]) == 20
    for candle in payload["candles"]:
        assert candle["high"] >= max(candle["open"], candle["close"])
        assert candle["low"] <= min(candle["open"], candle["close"])



def test_strategy_agent_ranks_four_candidates_without_live_trading():
    response = client.get("/api/agent/strategy?symbol=BTC-USD&limit=80")
    assert response.status_code == 200
    payload = response.json()
    assert payload["agent"] == "TX AI Strategy Agent"
    assert payload["live_trading_enabled"] is False
    assert len(payload["strategies"]) == 4
    assert payload["top_strategy"]["strategy_id"] in {
        "sma_crossover", "ema_trend", "rsi_reversion", "breakout"
    }
    assert payload["source"] == "DEMO FALLBACK · NOT LIVE"


def test_strategy_scan_rejects_unsupported_symbol():
    response = client.get("/api/strategies/scan?symbol=FAKE-USD")
    assert response.status_code == 422


def test_strategy_backtest_endpoint_requires_valid_strategy():
    response = client.post("/api/strategies/backtest",
                           json={"symbol": "BTC-USD", "strategy_id": "invalid"})
    assert response.status_code == 422


def test_paper_buy_persists_position_and_trade():
    result = client.post("/api/paper-orders", json={"symbol": "BTC-USD", "side": "BUY", "quantity": 0.1})
    assert result.status_code == 200
    assert result.json()["live_order_sent"] is False
    assert client.get("/api/trades").json()[0]["side"] == "BUY"
    positions = client.get("/api/positions").json()
    assert positions[0]["quantity"] == pytest.approx(0.1)
    status = client.get("/api/status").json()
    assert status["equity"] > 0
    assert "realized_pnl" in status and "unrealized_pnl" in status


def test_cannot_sell_more_than_open_paper_position():
    response = client.post("/api/paper-orders", json={"symbol": "BTC-USD", "side": "SELL", "quantity": 1})
    assert response.status_code == 400


def test_invalid_quantity_rejected():
    response = client.post("/api/paper-orders", json={"symbol": "BTC-USD", "side": "BUY", "quantity": 0})
    assert response.status_code == 422


def test_token_required_when_configured(monkeypatch):
    monkeypatch.setenv("BOT_API_TOKEN", "secret-test-token")
    response = client.post("/api/paper-orders", json={"symbol": "BTC-USD", "side": "BUY", "quantity": 0.1})
    assert response.status_code == 401
    response = client.post("/api/paper-orders", headers={"Authorization": "Bearer secret-test-token"},
                           json={"symbol": "BTC-USD", "side": "BUY", "quantity": 0.1})
    assert response.status_code == 200
