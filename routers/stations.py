"""
Stations router - GET /stations/ and GET /stations/nearby
"""
import math
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from models.models import Station
from schemas.schemas import StationResponse

router = APIRouter(prefix="/stations", tags=["stations"])

EARTH_RADIUS_KM = 6371.0


def haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance between two coordinates in km."""
    rlat1, rlat2 = math.radians(lat1), math.radians(lat2)
    rdlon = math.radians(lng2 - lng1)
    a = (math.sin((rlat2 - rlat1) / 2) ** 2 +
         math.cos(rlat1) * math.cos(rlat2) * math.sin(rdlon / 2) ** 2)
    return EARTH_RADIUS_KM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@router.get("/", response_model=List[StationResponse])
async def get_stations(
    route_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get all stations, optionally filtered by route."""
    try:
        stmt = select(Station)
        if route_id is not None:
            stmt = stmt.where(Station.route_id == route_id)
        stmt = stmt.order_by(Station.sequence)
        result = await db.execute(stmt)
        stations = result.scalars().all()
        return [StationResponse.model_validate(s) for s in stations]
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unavailable: {str(e)}")


@router.get("/nearby", response_model=List[StationResponse])
async def get_nearby_stations(
    lat: float = Query(..., ge=36.65, le=36.90),
    lng: float = Query(..., ge=2.90, le=3.30),
    radius_km: float = Query(2.0, gt=0, le=50),
    route_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get stations within radius of coordinates."""
    try:
        stmt = select(Station)
        if route_id:
            stmt = stmt.where(Station.route_id == route_id)
        result = await db.execute(stmt)
        stations = result.scalars().all()

        nearby = []
        for s in stations:
            dist = haversine_distance(lat, lng, s.lat, s.lng)
            if dist <= radius_km:
                nearby.append((s, dist))

        nearby.sort(key=lambda x: x[1])
        return [StationResponse.model_validate(s) for s, _ in nearby]
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unavailable: {str(e)}")
