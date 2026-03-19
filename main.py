"""
Tram Alger API - FastAPI Entry Point
Real-time ETA prediction platform for Algiers Tramway Line 1
"""
import os
from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from core.database import engine
from core.redis_client import check_redis_connected
from models.models import Base
from routers import stations, routes, eta, gps
from schemas.schemas import HealthResponse, StatsResponse
from sqlalchemy import text, func
from sqlalchemy.ext.asyncio import AsyncSession


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database on startup (graceful if unavailable)."""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("Database connected")
    except Exception as e:
        print(f"Database not available at startup: {e}")
        print("Endpoints requiring DB will return 503 until connection is restored")
    yield


app = FastAPI(
    title="Tram Alger API",
    description="Real-time ETA prediction for Algiers Tramway Line 1",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(stations.router)
app.include_router(routes.router)
app.include_router(eta.router)
app.include_router(gps.router)


@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="ok",
        timestamp=datetime.utcnow().isoformat() + "Z"
    )


@app.get("/admin/stats", response_model=StatsResponse, tags=["admin"])
async def get_stats():
    """Get system statistics."""
    redis_ok = await check_redis_connected()
    db_ok = False
    total_stations = 0
    active_routes = 0
    pings_last_hour = 0

    try:
        async with AsyncSession(engine) as db:
            stations_result = await db.execute(text("SELECT COUNT(*) FROM stations"))
            total_stations = stations_result.scalar() or 0

            routes_result = await db.execute(
                text("SELECT COUNT(*) FROM routes WHERE is_active = true")
            )
            active_routes = routes_result.scalar() or 0

            pings_result = await db.execute(text(
                "SELECT COUNT(*) FROM gps_pings WHERE ts > NOW() - INTERVAL '1 hour'"
            ))
            pings_last_hour = pings_result.scalar() or 0

            await db.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        pass

    return StatsResponse(
        total_stations=total_stations,
        active_routes=active_routes,
        gps_pings_last_hour=pings_last_hour,
        redis_connected=redis_ok,
        db_connected=db_ok
    )


if os.path.exists("static"):
    app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/", include_in_schema=False)
async def root():
    """Serve the test dashboard."""
    index_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "Tram Alger API - static/index.html not found"}
