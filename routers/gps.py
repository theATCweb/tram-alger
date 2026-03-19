"""
GPS router - POST /gps/ping
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.gps_service import process_gps_ping
from schemas.schemas import GPSPingRequest, GPSPingResponse

router = APIRouter(prefix="/gps", tags=["gps"])


@router.post("/ping", response_model=GPSPingResponse)
async def submit_gps_ping(
    ping: GPSPingRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Submit a GPS ping from a tram passenger.
    Validates quality and stores for ETA calculation.
    """
    try:
        await process_gps_ping(db, ping)
        return GPSPingResponse(accepted=True, message="Ping received")
    except Exception as e:
        return GPSPingResponse(accepted=False, message=f"Processing error: {str(e)}")
