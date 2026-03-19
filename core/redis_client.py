"""
Redis client module for caching and GPS ring buffers.
"""
import json
from datetime import datetime
from typing import Optional, List, Any
import redis.asyncio as redis
from core.config import get_settings

settings = get_settings()


def get_redis_client() -> redis.Redis:
    """Create and return an async Redis client."""
    return redis.from_url(settings.REDIS_URL, decode_responses=True)


async def check_redis_connected() -> bool:
    """Check if Redis is connected."""
    try:
        client = get_redis_client()
        await client.ping()
        await client.close()
        return True
    except Exception:
        return False


async def get_cached_eta(station_id: int, direction: int) -> Optional[dict]:
    """Get cached ETA from Redis."""
    client = get_redis_client()
    try:
        key = f"eta:{station_id}:{direction}"
        data = await client.get(key)
        if data:
            return json.loads(data)
        return None
    finally:
        await client.close()


async def set_cached_eta(station_id: int, direction: int, value: dict) -> None:
    """Set ETA in Redis cache with TTL."""
    client = get_redis_client()
    try:
        key = f"eta:{station_id}:{direction}"
        await client.setex(key, settings.ETA_CACHE_TTL_SEC, json.dumps(value, default=str))
    finally:
        await client.close()


async def push_gps_ping(route_id: int, direction: int, ping_data: dict) -> None:
    """Push a GPS ping to the ring buffer in Redis."""
    client = get_redis_client()
    try:
        key = f"gps:ring:{route_id}:{direction}"
        await client.lpush(key, json.dumps(ping_data))
        await client.ltrim(key, 0, settings.GPS_RING_BUFFER_LEN - 1)
    finally:
        await client.close()


async def get_gps_ring_pings(route_id: int, direction: int, count: int = 10) -> List[dict]:
    """Get recent GPS pings from the ring buffer."""
    client = get_redis_client()
    try:
        key = f"gps:ring:{route_id}:{direction}"
        pings = await client.lrange(key, 0, count - 1)
        return [json.loads(p) for p in pings]
    finally:
        await client.close()


async def invalidate_eta_cache(route_id: int, direction: int) -> None:
    """Invalidate ETA cache for stations on a route."""
    client = get_redis_client()
    try:
        pattern = f"eta:*:{direction}"
        keys = await client.keys(pattern)
        if keys:
            await client.delete(*keys)
    finally:
        await client.close()
