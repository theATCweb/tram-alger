#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "=== Tram Alger Startup ==="

echo "Installing dependencies..."
pip install -q -r requirements.txt

echo "Checking environment..."
python scripts/check_env.py || echo "WARNING: env check failed, continuing anyway"

echo "Starting Redis..."
redis-server --daemonize yes --port 6379 2>/dev/null || true

echo "Applying schema..."
python -c "
import asyncio, asyncpg, os
async def run():
    url = os.getenv('DATABASE_URL','').replace('postgresql+asyncpg://','postgresql://')
    conn = await asyncpg.connect(url)
    with open('schema.sql') as f:
        sql = f.read()
    await conn.execute(sql)
    await conn.close()
    print('Schema ready')
asyncio.run(run())
"

echo "Seeding database..."
python scripts/seed_db.py

echo "Starting API on port ${PORT:-8000}..."
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 2
