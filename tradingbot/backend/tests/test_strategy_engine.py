import pytest
from strategy_engine import STRATEGIES, backtest_strategy, run_strategy_lab


def candles_from_closes(closes):
    rows = []
    for i, close in enumerate(closes):
        rows.append({"time": i, "open": close, "close": close,
                     "high": close * 1.002, "low": close * 0.998, "volume": 100})
    return rows


def test_all_strategies_return_metrics_on_sufficient_data():
    closes = [100 + i * 0.5 + ((i % 7) - 3) * 0.7 for i in range(100)]
    candles = candles_from_closes(closes)
    for item in STRATEGIES:
        result = backtest_strategy(candles, item["id"])
        assert result["strategy_id"] == item["id"]
        assert result["action"] in {"BUY", "SELL", "WAIT"}
        assert isinstance(result["net_return_pct"], float)
        assert result["candles_tested"] == 100


def test_strategy_lab_returns_ranked_candidates_and_no_live_trading():
    candles = candles_from_closes([100 + i * 0.3 for i in range(80)])
    result = run_strategy_lab(candles)
    assert len(result["strategies"]) == len(STRATEGIES)
    assert result["live_trading_enabled"] is False
    assert result["top_strategy"] is not None


def test_backtest_rejects_short_history():
    with pytest.raises(ValueError, match="25 candles"):
        backtest_strategy(candles_from_closes([100, 101, 102]), "sma_crossover")


def test_backtest_rejects_unknown_strategy():
    with pytest.raises(ValueError, match="Unknown strategy"):
        backtest_strategy(candles_from_closes([100 + i for i in range(30)]), "made_up")


def test_backtest_rejects_non_positive_close():
    candles = candles_from_closes([100 + i for i in range(29)] + [0])
    with pytest.raises(ValueError, match="positive"):
        backtest_strategy(candles, "ema_trend")
