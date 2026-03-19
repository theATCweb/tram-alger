"""
Environment checker — run before start.sh to diagnose connection issues.
Usage: python scripts/check_env.py
"""
import asyncio
import os
import sys
from dotenv import load_dotenv
load_dotenv()


async def check_postgres():
    import asyncpg
    url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not url or "user:password" in url or "REPLACE_" in url:
        print("X  DATABASE_URL not configured - still using placeholder")
        print("   Set real credentials in .env or environment")
        return False
    try:
        conn = await asyncpg.connect(url, timeout=5)
        version = await conn.fetchval("SELECT version()")
        await conn.close()
        print(f"V  PostgreSQL connected: {version[:40]}")
        return True
    except Exception as e:
        print(f"X  PostgreSQL failed: {e}")
        return False


async def check_redis():
    import redis.asyncio as redis
    url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    try:
        client = redis.from_url(url, decode_responses=True)
        await client.ping()
        await client.close()
        print("V  Redis connected")
        return True
    except Exception as e:
        print(f"!  Redis failed (ETA caching disabled): {e}")
        return False


async def main():
    print("=== Tram Alger — Environment Check ===\n")
    pg_ok    = await check_postgres()
    redis_ok = await check_redis()

    print()
    if not pg_ok:
        print("REQUIRED: Set DATABASE_URL to a real PostgreSQL connection string")
        print("Example:  postgresql+asyncpg://postgres:yourpass@localhost:5432/tram_alger")
        sys.exit(1)
    else:
        print("Environment ready - run: bash start.sh")


asyncio.run(main())
