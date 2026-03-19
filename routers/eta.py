"""
ETA router - GET /eta/{station_id}
The most important endpoint - must respond in < 100ms.
"""
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.eta_service import calculate_eta
from models.models import Route
from schemas.schemas import ETAResponse

router = APIRouter(prefix="/eta", tags=["eta"])


@router.get("/{station_id}", response_model=ETAResponse)
async def get_eta(
    station_id: int,
    direction: int = Query(0, ge=0, le=1),
    route_id: int = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """
    Get ETA prediction for a station.
    Returns cached result if available, otherwise calculates from GPS or schedule.
    """
    if route_id is None:
        stmt = select(Route.id).where(Route.direction == direction, Route.is_active == True).limit(1)
        result = await db.execute(stmt)
        row = result.scalar_one_or_none()
        route_id = row if row else 1

    try:
        return await calculate_eta(db, station_id, direction, route_id)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")
