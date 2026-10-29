from __future__ import annotations

import base64
import json
import os
import secrets
import urllib.error
import urllib.request
from datetime import datetime, timezone
from typing import Literal

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy import DateTime, Float, Integer, String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker

APP_VERSION = "0.1.0"
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tradingbot.db")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg://", 1)
elif DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class Trade(Base):
    __tablename__ = "trades"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), index=True)
    side: Mapped[str] = mapped_column(String(4))
    quantity: Mapped[float] = mapped_column(Float)
    price: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(20), default="PAPER_FILLED")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class Position(Base):
    __tablename__ = "positions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    symbol: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    quantity: Mapped[float] = mapped_column(Float, default=0)
    average_entry: Mapped[float] = mapped_column(Float, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


Base.metadata.create_all(engine)

app = FastAPI(title="Ai-Hub Paper Trading API", version=APP_VERSION, description="Paper trading only. No live broker adapter is implemented.")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET", "POST", "OPTIONS"], allow_headers=["*"])


def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def require_control_token(authorization: str | None = Header(default=None)):
    expected = os.getenv("BOT_API_TOKEN")
    if not expected:
        # Local tests/development can run without a token. Production setup docs require one.
        return True
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not secrets.compare_digest(supplied, expected):
        raise HTTPException(status_code=401, detail="Missing or invalid bearer token")
    return True


def demo_candles(symbol: str = "BTC-USD", limit: int = 80):
    # Clearly labeled deterministic demo data; this is NOT a live market feed.
    seed = sum(ord(ch) for ch in symbol) % 31
    base = 60000.0 + seed * 137
    result = []
    for i in range(max(1, min(limit, 200))):
        drift = ((i * 17 + seed * 11) % 23 - 11) * 18
        open_price = base + i * 23 + drift
        close_price = open_price + (((i * 7 + seed) % 19) - 9) * 24
        high = max(open_price, close_price) + 35 + (i % 5) * 8
        low = min(open_price, close_price) - 30 - (i % 7) * 6
        result.append({"time": i, "open": round(open_price, 2), "high": round(high, 2),
                       "low": round(low, 2), "close": round(close_price, 2), "volume": 100 + i * 3})
    return result


class PaperOrder(BaseModel):
    symbol: str = Field(default="BTC-USD", min_length=3, max_length=20, pattern=r"^[A-Z0-9-]+$")
    side: Literal["BUY", "SELL"]
    quantity: float = Field(gt=0, le=100)


def write_research_to_github(report: dict) -> dict:
    token = os.getenv("GITHUB_RESEARCH_TOKEN")
    repo = os.getenv("GITHUB_RESEARCH_REPO", "haseebop668-a11y/Ai-Hub")
    if not token:
        return {"saved_to_github": False, "reason": "GITHUB_RESEARCH_TOKEN is not configured"}
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = f"tradingbot/research/analysis-{timestamp}.json"
    payload = json.dumps(report, indent=2, ensure_ascii=False).encode()
    body = json.dumps({"message": f"Add paper-trading research report {timestamp}",
                       "content": base64.b64encode(payload).decode()}).encode()
    request = urllib.request.Request(
        f"https://api.github.com/repos/{repo}/contents/{path}", data=body, method="PUT",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            return {"saved_to_github": response.status in (200, 201), "path": path}
    except (urllib.error.URLError, TimeoutError, ValueError) as exc:
        return {"saved_to_github": False, "reason": f"GitHub write failed: {type(exc).__name__}"}


@app.get("/")
def root():
    return {"service": "Ai-Hub Paper Trading API", "version": APP_VERSION, "mode": "paper-only", "docs": "/docs"}


@app.get("/health")
def health():
    try:
        with engine.connect() as connection:
            connection.exec_driver_sql("SELECT 1")
        database_ok = True
    except Exception:
        database_ok = False
    return {"status": "ok" if database_ok else "degraded", "database": database_ok,
            "mode": "paper-only", "market_data": "demo-only", "version": APP_VERSION}


def portfolio_metrics(db: Session) -> dict:
    # Average-cost accounting for long-only paper positions. Marks use synthetic demo quotes.
    trades = db.scalars(select(Trade).order_by(Trade.id.asc())).all()
    average_cost: dict[str, float] = {}
    quantities: dict[str, float] = {}
    realized = 0.0
    for trade in trades:
        qty = quantities.get(trade.symbol, 0.0)
        avg = average_cost.get(trade.symbol, 0.0)
        if trade.side == "BUY":
            new_qty = qty + trade.quantity
            average_cost[trade.symbol] = ((qty * avg) + (trade.quantity * trade.price)) / new_qty
            quantities[trade.symbol] = new_qty
        else:
            realized += (trade.price - avg) * trade.quantity
            quantities[trade.symbol] = max(0.0, qty - trade.quantity)
            if quantities[trade.symbol] <= 1e-9:
                average_cost[trade.symbol] = 0.0
    unrealized = 0.0
    for position in db.scalars(select(Position)).all():
        if position.quantity > 1e-9:
            mark = demo_candles(position.symbol, 1)[0]["close"]
            unrealized += (mark - position.average_entry) * position.quantity
    return {"starting_equity": 10000.0, "realized_pnl": round(realized, 2),
            "unrealized_pnl": round(unrealized, 2),
            "equity": round(10000.0 + realized + unrealized, 2)}


@app.get("/api/status")
def status(db: Session = Depends(db_session)):
    positions = db.scalars(select(Position)).all()
    trades = db.scalars(select(Trade)).all()
    return {"bot_status": "IDLE", "mode": "PAPER", "live_trading_enabled": False,
            "market_data": "DEMO", "open_positions": len([p for p in positions if abs(p.quantity) > 1e-9]),
            "total_paper_trades": len(trades), "last_scan": None, **portfolio_metrics(db)}


@app.get("/api/candles")
def candles(symbol: str = "BTC-USD", limit: int = 80):
    if not symbol or len(symbol) > 20 or not all(c.isalnum() or c == "-" for c in symbol.upper()):
        raise HTTPException(status_code=422, detail="Invalid symbol")
    return {"symbol": symbol.upper(), "source": "DEMO_NOT_LIVE", "candles": demo_candles(symbol.upper(), limit)}


@app.get("/api/positions")
def positions(db: Session = Depends(db_session)):
    return [{"symbol": p.symbol, "quantity": p.quantity, "average_entry": p.average_entry,
             "updated_at": p.updated_at.isoformat() if p.updated_at else None}
            for p in db.scalars(select(Position).order_by(Position.symbol)).all() if abs(p.quantity) > 1e-9]


@app.get("/api/trades")
def trades(limit: int = 50, db: Session = Depends(db_session)):
    rows = db.scalars(select(Trade).order_by(Trade.id.desc()).limit(max(1, min(limit, 200)))).all()
    return [{"id": t.id, "symbol": t.symbol, "side": t.side, "quantity": t.quantity,
             "price": t.price, "status": t.status,
             "created_at": t.created_at.isoformat() if t.created_at else None} for t in rows]


@app.post("/api/paper-orders")
def place_paper_order(order: PaperOrder, _: bool = Depends(require_control_token), db: Session = Depends(db_session)):
    # The quote is synthetic demo data. Never routes to an exchange.
    candle = demo_candles(order.symbol, 1)[0]
    price = candle["close"]
    position = db.scalar(select(Position).where(Position.symbol == order.symbol))
    if position is None:
        position = Position(symbol=order.symbol, quantity=0, average_entry=0)
        db.add(position)
        db.flush()
    signed_quantity = order.quantity if order.side == "BUY" else -order.quantity
    new_quantity = position.quantity + signed_quantity
    if order.side == "SELL" and position.quantity < order.quantity:
        raise HTTPException(status_code=400, detail="Paper sell exceeds current long position")
    if order.side == "BUY":
        total_cost = position.average_entry * position.quantity + price * order.quantity
        position.average_entry = total_cost / new_quantity
    elif abs(new_quantity) < 1e-9:
        position.average_entry = 0
    position.quantity = new_quantity
    position.updated_at = datetime.now(timezone.utc)
    trade = Trade(symbol=order.symbol, side=order.side, quantity=order.quantity, price=price)
    db.add(trade)
    db.commit()
    db.refresh(trade)
    return {"trade_id": trade.id, "symbol": order.symbol, "side": order.side, "quantity": order.quantity,
            "price": price, "status": "PAPER_FILLED", "live_order_sent": False}


@app.post("/api/research")
def create_research(_: bool = Depends(require_control_token), db: Session = Depends(db_session)):
    report = {"created_at": datetime.now(timezone.utc).isoformat(), "mode": "paper-only",
              "source": "demo candles; not live market data", "symbol": "BTC-USD",
              "sample_size": 80, "strategy": "SMA crossover placeholder",
              "signal": "NO_TRADE", "note": "Research scaffold only; no profitability claim."}
    result = write_research_to_github(report)
    return {"report": report, **result}
