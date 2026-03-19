"""
Routes router - GET /routes/
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from models.models import Route, Station
from schemas.schemas import RouteResponse

router = APIRouter(prefix="/routes", tags=["routes"])


@router.get("/", response_model=List[RouteResponse])
async def get_routes(db: AsyncSession = Depends(get_db)):
    """Get all active routes with station counts."""
    try:
        subq = select(
            Station.route_id,
            func.count(Station.id).label("station_count")
        ).group_by(Station.route_id).subquery()

        stmt = select(Route, func.coalesce(subq.c.station_count, 0)).outerjoin(
            subq, Route.id == subq.c.route_id
        ).where(Route.is_active == True)

        result = await db.execute(stmt)
        rows = result.all()

        return [
            RouteResponse(
                id=r.id,
                name=r.name,
                short_name=r.short_name,
                direction=r.direction,
                is_active=r.is_active,
                station_count=count
            )
            for r, count in rows
        ]
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unavailable: {str(e)}")
