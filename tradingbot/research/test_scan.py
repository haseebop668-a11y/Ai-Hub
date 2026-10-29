import importlib.util
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("scan.py")
spec = importlib.util.spec_from_file_location("paper_research_scan", MODULE_PATH)
scan = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(scan)


def test_report_is_research_only_and_never_requests_execution():
    candles = []
    for i in range(80):
        close = 100.0 + i
        candles.append({"time": 1_700_000_000 + i * 3600, "open": close - 1,
                        "high": close + 2, "low": close - 2, "close": close, "volume": 100})
    report = scan.build_report(candles)
    assert report["symbol"] == "BTC-USD"
    assert report["candle_count"] == 80
    assert report["execution"] == "NONE"
    assert report["mode"] == "RESEARCH_ONLY_PAPER_TRADING"
    assert report["market_data_is_live"] is True
    assert "limitations" in report
