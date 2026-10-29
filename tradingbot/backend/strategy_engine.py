"""Deterministic, explainable strategy lab for TX AI paper research.

Signals use completed candles only. Backtests apply each signal to the NEXT candle's
return to avoid same-candle lookahead. Results are educational, not profit guarantees.
"""
from __future__ import annotations

from math import sqrt
from typing import Any

STRATEGIES = [
    {"id": "sma_crossover", "name": "SMA Crossover", "style": "Trend following",
     "description": "BUY when the 8-candle average crosses above the 21-candle average; SELL on the reverse cross."},
    {"id": "ema_trend", "name": "EMA Trend + Momentum", "style": "Trend following",
     "description": "BUY when the 9 EMA is above the 21 EMA and momentum is positive; SELL when trend reverses."},
    {"id": "rsi_reversion", "name": "RSI Mean Reversion", "style": "Mean reversion",
     "description": "BUY when RSI(14) recovers from oversold territory; SELL when RSI reaches overbought territory."},
    {"id": "breakout", "name": "20-Candle Breakout", "style": "Breakout",
     "description": "BUY on a close above the previous 20-candle high; SELL on a close below the previous 20-candle low."},
]
VALID_IDS = {item["id"] for item in STRATEGIES}


def _ema(values: list[float], period: int) -> list[float]:
    if not values:
        return []
    alpha = 2.0 / (period + 1.0)
    out = [values[0]]
    for value in values[1:]:
        out.append(alpha * value + (1 - alpha) * out[-1])
    return out


def _rsi(values: list[float], period: int = 14) -> list[float]:
    if not values:
        return []
    out = [50.0]
    gains: list[float] = []
    losses: list[float] = []
    for i in range(1, len(values)):
        change = values[i] - values[i - 1]
        gains.append(max(change, 0.0))
        losses.append(max(-change, 0.0))
        window_g = gains[max(0, len(gains) - period):]
        window_l = losses[max(0, len(losses) - period):]
        avg_g = sum(window_g) / len(window_g)
        avg_l = sum(window_l) / len(window_l)
        if avg_l == 0:
            out.append(100.0 if avg_g > 0 else 50.0)
        else:
            out.append(100.0 - 100.0 / (1.0 + avg_g / avg_l))
    return out


def _signals(candles: list[dict[str, Any]], strategy_id: str) -> list[int]:
    closes = [float(c["close"]) for c in candles]
    n = len(closes)
    signals = [0] * n
    if strategy_id == "sma_crossover":
        for i in range(n):
            if i < 21:
                continue
            fast = sum(closes[i - 7:i + 1]) / 8
            slow = sum(closes[i - 20:i + 1]) / 21
            prev_fast = sum(closes[i - 8:i]) / 8
            prev_slow = sum(closes[i - 21:i]) / 21
            if prev_fast <= prev_slow and fast > slow:
                signals[i] = 1
            elif prev_fast >= prev_slow and fast < slow:
                signals[i] = -1
    elif strategy_id == "ema_trend":
        fast, slow = _ema(closes, 9), _ema(closes, 21)
        for i in range(21, n):
            if fast[i] > slow[i] and closes[i] > closes[i - 1]:
                signals[i] = 1
            elif fast[i] < slow[i] and closes[i] < closes[i - 1]:
                signals[i] = -1
    elif strategy_id == "rsi_reversion":
        rsi = _rsi(closes)
        for i in range(15, n):
            if rsi[i - 1] < 30 <= rsi[i]:
                signals[i] = 1
            elif rsi[i] >= 70:
                signals[i] = -1
    elif strategy_id == "breakout":
        for i in range(20, n):
            prior_high = max(float(candles[j]["high"]) for j in range(i - 20, i))
            prior_low = min(float(candles[j]["low"]) for j in range(i - 20, i))
            if closes[i] > prior_high:
                signals[i] = 1
            elif closes[i] < prior_low:
                signals[i] = -1
    else:
        raise ValueError(f"Unknown strategy: {strategy_id}")
    return signals



def _current_action(candles: list[dict[str, Any]], strategy_id: str) -> str:
    closes = [float(c["close"]) for c in candles]
    i = len(closes) - 1
    if strategy_id == "sma_crossover":
        if len(closes) < 21:
            return "WAIT"
        fast = sum(closes[i - 7:i + 1]) / 8
        slow = sum(closes[i - 20:i + 1]) / 21
        return "BUY" if fast > slow else "SELL" if fast < slow else "WAIT"
    if strategy_id == "ema_trend":
        fast, slow = _ema(closes, 9), _ema(closes, 21)
        if fast[i] > slow[i] and closes[i] > closes[i - 1]:
            return "BUY"
        if fast[i] < slow[i] and closes[i] < closes[i - 1]:
            return "SELL"
        return "WAIT"
    if strategy_id == "rsi_reversion":
        rsi = _rsi(closes)
        if len(rsi) > 15 and rsi[i - 1] < 30 <= rsi[i]:
            return "BUY"
        if rsi[i] >= 70:
            return "SELL"
        return "WAIT"
    if strategy_id == "breakout":
        if len(candles) < 21:
            return "WAIT"
        prior_high = max(float(candles[j]["high"]) for j in range(i - 20, i))
        prior_low = min(float(candles[j]["low"]) for j in range(i - 20, i))
        return "BUY" if closes[i] > prior_high else "SELL" if closes[i] < prior_low else "WAIT"
    raise ValueError(f"Unknown strategy: {strategy_id}")


def backtest_strategy(candles: list[dict[str, Any]], strategy_id: str,
                      fee_bps: float = 10.0, slippage_bps: float = 5.0) -> dict[str, Any]:
    if strategy_id not in VALID_IDS:
        raise ValueError(f"Unknown strategy: {strategy_id}")
    if len(candles) < 25:
        raise ValueError("At least 25 candles are required for strategy evaluation")
    closes = [float(c["close"]) for c in candles]
    if any(price <= 0 for price in closes):
        raise ValueError("Candle close prices must be positive")
    signals = _signals(candles, strategy_id)
    position = 0
    equity = 1.0
    peak = 1.0
    max_drawdown = 0.0
    trade_returns: list[float] = []
    daily_returns: list[float] = []
    entries = 0
    last_action = "WAIT"
    fee_rate = max(0.0, (fee_bps + slippage_bps) / 10000.0)
    for i in range(len(candles) - 1):
        signal = signals[i]
        if signal == 1 and position == 0:
            position = 1
            entries += 1
            equity *= (1.0 - fee_rate)
            last_action = "BUY"
        elif signal == -1 and position == 1:
            position = 0
            equity *= (1.0 - fee_rate)
            last_action = "SELL"
        market_return = closes[i + 1] / closes[i] - 1.0
        period_return = position * market_return
        equity *= (1.0 + period_return)
        daily_returns.append(period_return)
        if signal == -1 and position == 0 and i > 0:
            pass
        peak = max(peak, equity)
        max_drawdown = max(max_drawdown, (peak - equity) / peak if peak else 0.0)
    if position == 1:
        equity *= (1.0 - fee_rate)
        trade_returns.append(equity - 1.0)
    net_return = (equity - 1.0) * 100.0
    mean = sum(daily_returns) / len(daily_returns) if daily_returns else 0.0
    variance = sum((r - mean) ** 2 for r in daily_returns) / max(1, len(daily_returns) - 1)
    volatility = sqrt(variance) * sqrt(24 * 365) * 100.0
    name = next(item["name"] for item in STRATEGIES if item["id"] == strategy_id)
    action = _current_action(candles, strategy_id)
    return {
        "strategy_id": strategy_id, "strategy": name, "action": action,
        "net_return_pct": round(net_return, 3), "max_drawdown_pct": round(max_drawdown * 100, 3),
        "annualized_volatility_pct": round(volatility, 3), "entries": entries,
        "candles_tested": len(candles), "estimated_cost_bps_per_side": round(fee_bps + slippage_bps, 2),
        "position_at_end": "LONG" if position else "FLAT",
        "source": candles[-1].get("source", "configured candle feed"),
        "methodology": "Long-only; next-candle returns; estimated fees and slippage; historical simulation only."
    }


def run_strategy_lab(candles: list[dict[str, Any]]) -> dict[str, Any]:
    results = [backtest_strategy(candles, item["id"]) for item in STRATEGIES]
    ranked = sorted(results, key=lambda r: (r["net_return_pct"], -r["max_drawdown_pct"]), reverse=True)
    best = ranked[0] if ranked else None
    if best and best["net_return_pct"] > 0 and best["max_drawdown_pct"] < 25:
        recommendation = "PAPER_TEST_CANDIDATE"
        rationale = "Best historical result in this small strategy set; continue out-of-sample paper testing before considering any use."
    else:
        recommendation = "NO_DEPLOY"
        rationale = "No candidate passed the basic positive-return and drawdown screen. Keep researching; do not treat the top-ranked result as a live signal."
    return {
        "agent": "TX AI Strategy Agent",
        "agent_mode": "deterministic research agent",
        "symbol": candles[-1].get("symbol", "UNKNOWN") if candles else "UNKNOWN",
        "candles_tested": len(candles),
        "recommendation": recommendation,
        "rationale": rationale,
        "latest_signal": best["action"] if best else "WAIT",
        "top_strategy": best,
        "strategies": ranked,
        "live_trading_enabled": False,
        "disclaimer": "Backtests are not forecasts. Demo candles are synthetic; check source before interpreting results."
    }
