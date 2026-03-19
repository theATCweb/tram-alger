"""
GPS Service for handling incoming GPS pings.
Hashes device tokens, stores in Redis ring buffer, and logs to DB.
"""
import hashlib
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from core.config import get_settings
from core.redis_client import push_gps_ping, invalidate_eta_cache
from models.models import GPSPing
from schemas.schemas import GPSPingRequest

settings = get_settings()


def hash_device_token(device_token: str) -> str:
    """Hash device token with daily salt for privacy."""
    daily_salt = f"{settings.SESSION_HASH_SALT}:{datetime.utcnow().strftime('%Y-%m-%d')}"
    combined = f"{device_token}:{daily_salt}"
    return hashlib.sha256(combined.encode()).hexdigest()


async def process_gps_ping(
    db: AsyncSession,
    ping: GPSPingRequest
) -> bool:
    """
    Process an incoming GPS ping:
    1. Hash the device token
    2. Push to Redis ring buffer (optional)
    3. Log to PostgreSQL
    4. Invalidate nearby ETA caches (optional)
    """
    session_hash = hash_device_token(ping.device_token)

    ping_data = {
        "lat": ping.lat,
        "lng": ping.lng,
        "speed_kmh": ping.speed_kmh,
        "bearing": ping.bearing,
        "accuracy_m": ping.accuracy_m,
        "ts": datetime.utcnow().isoformat(),
        "sequence": 0
    }

    try:
        await push_gps_ping(ping.route_id, ping.direction, ping_data)
    except Exception:
        pass

    db_ping = GPSPing(
        session_hash=session_hash,
        lat=ping.lat,
        lng=ping.lng,
        speed_kmh=ping.speed_kmh,
        bearing=ping.bearing,
        accuracy_m=ping.accuracy_m,
        route_id=ping.route_id,
        ts=datetime.utcnow()
    )
    db.add(db_ping)
    await db.commit()

    try:
        await invalidate_eta_cache(ping.route_id, ping.direction)
    except Exception:
        pass

    return True
