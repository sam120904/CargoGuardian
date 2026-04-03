"""
Smart Cargo Intelligence Network — Middleware Server
=====================================================
FastAPI server bridging Flutter app ↔ TigerGraph Cloud.

Theme: DUALITY — Efficiency vs. Security

Endpoints:
  /api/routes/*     → Efficiency (shortest paths, route optimization)
  /api/security/*   → Security (bottlenecks, fraud, overload risks)
  /api/sync/*       → Real-time IoT → Graph synchronization
  /api/data/*       → Network entities (stations, trains, cargo)

Run: uvicorn main:app --reload --port 8000
"""

from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from routers import graph_routes, graph_security, graph_sync, graph_data
from services.tigergraph_service import tg_service
from services.blynk_bridge import blynk_bridge


# ──────────────────────────────────────────────
# Lifespan — startup/shutdown events
# ──────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle."""
    print("=" * 60)
    print("🚀 Smart Cargo Intelligence Network — Starting Up")
    print(f"   Mode: {'DEMO' if tg_service.is_demo else 'LIVE (TigerGraph Cloud)'}")
    print(f"   Port: {settings.PORT}")
    print(f"   Time: {datetime.now().isoformat()}")
    print("=" * 60)

    # Start periodic IoT → Graph sync (only if not demo mode)
    # In demo mode, we skip actual Blynk sync
    if not tg_service.is_demo and settings.BLYNK_AUTH_TOKEN:
        try:
            from apscheduler.schedulers.asyncio import AsyncIOScheduler
            scheduler = AsyncIOScheduler()
            scheduler.add_job(
                blynk_bridge.sync_to_graph,
                "interval",
                seconds=settings.SYNC_INTERVAL,
                id="blynk_sync",
            )
            scheduler.start()
            print(f"📡 IoT sync scheduler running (every {settings.SYNC_INTERVAL}s)")
        except Exception as e:
            print(f"⚠️ Could not start sync scheduler: {e}")

    yield  # App is running

    print("🔌 Shutting down Smart Cargo Intelligence Network")


# ──────────────────────────────────────────────
# FastAPI App
# ──────────────────────────────────────────────
app = FastAPI(
    title="Smart Cargo Intelligence Network",
    description=(
        "🧠 Graph-powered logistics intelligence. "
        "Theme: **Duality** — Efficiency ⚡ vs Security 🛡️"
    ),
    version="2.0.0",
    lifespan=lifespan,
)

# CORS — Allow Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for development
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ──────────────────────────────────────────────
# Register Routers
# ──────────────────────────────────────────────
app.include_router(graph_routes.router)
app.include_router(graph_security.router)
app.include_router(graph_sync.router)
app.include_router(graph_data.router)


# ──────────────────────────────────────────────
# Root & Health Endpoints
# ──────────────────────────────────────────────
@app.get("/", tags=["System"])
async def root():
    """Root endpoint — system info."""
    return {
        "name": "Smart Cargo Intelligence Network",
        "version": "2.0.0",
        "theme": "Duality — Efficiency ⚡ vs Security 🛡️",
        "mode": "demo" if tg_service.is_demo else "live",
        "endpoints": {
            "efficiency": "/api/routes/shortest?from=NDLS&to=BCT",
            "security": "/api/security/bottlenecks",
            "sync": "/api/sync/device-status",
            "data": "/api/data/network-health",
            "docs": "/docs",
        },
    }


@app.get("/health", tags=["System"])
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "tigergraph_connected": not tg_service.is_demo,
        "demo_mode": tg_service.is_demo,
    }
