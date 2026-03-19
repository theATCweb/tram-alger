"""
ETA Prediction Engine.
Determines arrival times using GPS data or schedule fallback.
"""
import math
from datetime import datetime, timedelta
from typing import Optional, Tuple
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from core.config import get_settings
from core.redis_client import (
    get_cached_eta, set_cached_eta, get_gps_ring_pings
)
from models.models import Station, Schedule
from schemas.schemas import ETAResponse

settings = get_settings()

EARTH_RADIUS_M = 6_371_000
DEFAULT_SPEED_KMH = 22.0
DWELL_TIME_PER_STOP_SEC = 20
DEFAULT_CONFIDENCE_GPS = 0.7
DEFAULT_CONFIDENCE_SCHEDULE = 0.5


def haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance between two coordinates in meters."""
    rlat1, rlat2 = math.radians(lat1), math.radians(lat2)
    rdlon = math.radians(lng2 - lng1)
    a = (math.sin((rlat2 - rlat1) / 2) ** 2 +
         math.cos(rlat1) * math.cos(rlat2) * math.sin(rdlon / 2) ** 2)
    return EARTH_RADIUS_M * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def get_gps_based_eta(
    route_id: int,
    direction: int,
    station_id: int,
    station_lat: float,
    station_lng: float,
    station_sequence: int
) -> Optional[Tuple[datetime, float]]:
    """
    Calculate ETA from GPS ring buffer data.
    Returns (eta_datetime, confidence) or None if no fresh data.
    """
    pings = await get_gps_ring_pings(route_id, direction, count=10)
    if not pings:
        return None

    now = datetime.utcnow()
    for ping in pings:
        try:
            ping_ts_str = ping.get("ts")
            if ping_ts_str:
                ping_ts = datetime.fromisoformat(ping_ts_str.replace("Z", "+00:00"))
            else:
                ping_ts = now
            ping_age = (now - ping_ts).total_seconds()
        except (ValueError, TypeError):
            ping_age = 999

        if ping_age > settings.GPS_MAX_AGE_SEC:
            continue

        lat = ping.get("lat", 0)
        lng = ping.get("lng", 0)
        speed = ping.get("speed_kmh", DEFAULT_SPEED_KMH)

        if speed < 1 or speed > 70:
            speed = DEFAULT_SPEED_KMH

        distance_m = haversine(lat, lng, station_lat, station_lng)
        travel_sec = (distance_m / 1000) / speed * 3600

        tram_seq = ping.get("sequence", station_sequence)
        stops_between = abs(station_sequence - tram_seq)
        dwell_sec = stops_between * DWELL_TIME_PER_STOP_SEC

        total_sec = travel_sec + dwell_sec + settings.DEFAULT_DELAY_SEC
        eta = now + timedelta(seconds=total_sec)
        confidence = max(0.3, 1.0 - (ping_age / settings.GPS_MAX_AGE_SEC))

        return eta, confidence

    return None


async def get_schedule_based_eta(
    db: AsyncSession,
    station_id: int,
    direction: int
) -> Tuple[datetime, float]:
    """
    Get ETA from static schedule with delay offset.
    Returns (eta_datetime, confidence).
    """
    now = datetime.utcnow()
    current_minute = now.hour * 60 + now.minute

    stmt = select(Schedule).where(
        Schedule.station_id == station_id,
        Schedule.direction == direction,
        Schedule.arrival_min > current_minute
    ).order_by(Schedule.arrival_min).limit(1)

    result = await db.execute(stmt)
    schedule = result.scalar_one_or_none()

    if schedule:
        eta = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(
            minutes=schedule.arrival_min
        )
        if eta < now:
            eta += timedelta(days=1)
    else:
        stmt_wrap = select(Schedule).where(
            Schedule.station_id == station_id,
            Schedule.direction == direction
        ).order_by(Schedule.arrival_min).limit(1)
        result_wrap = await db.execute(stmt_wrap)
        first_schedule = result_wrap.scalar_one_or_none()
        if first_schedule:
            eta = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(
                days=1, minutes=first_schedule.arrival_min
            )
        else:
            eta = now + timedelta(minutes=30)

    eta = eta + timedelta(seconds=settings.DEFAULT_DELAY_SEC)
    return eta, DEFAULT_CONFIDENCE_SCHEDULE


async def calculate_eta(
    db: AsyncSession,
    station_id: int,
    direction: int,
    route_id: int = 1
) -> ETAResponse:
    """
    Main ETA calculation function with caching.
    Tries GPS first, falls back to schedule.
    """
    try:
        cached = await get_cached_eta(station_id, direction)
        if cached:
            return ETAResponse(**cached)
    except Exception:
        pass

    stmt = select(Station).where(Station.id == station_id).limit(1)
    result = await db.execute(stmt)
    station = result.scalar_one_or_none()

    if not station:
        return ETAResponse(
            station_id=station_id,
            direction=direction,
            source="none",
            confidence=0.0,
            message="Station not found"
        )

    gps_result = None
    try:
        gps_result = await get_gps_based_eta(
            route_id, direction, station_id, station.lat, station.lng, station.sequence
        )
    except Exception:
        pass

    if gps_result:
        eta_dt, confidence = gps_result
        response = ETAResponse(
            station_id=station_id,
            direction=direction,
            eta_iso=eta_dt.isoformat(),
            seconds_away=int((eta_dt - datetime.utcnow()).total_seconds()),
            source="gps",
            confidence=round(confidence, 2)
        )
    else:
        eta_dt, confidence = await get_schedule_based_eta(db, station_id, direction)
        response = ETAResponse(
            station_id=station_id,
            direction=direction,
            eta_iso=eta_dt.isoformat(),
            seconds_away=int((eta_dt - datetime.utcnow()).total_seconds()),
            source="schedule",
            confidence=round(confidence, 2)
        )

    try:
        await set_cached_eta(station_id, direction, response.model_dump())
    except Exception:
        pass

    return response
